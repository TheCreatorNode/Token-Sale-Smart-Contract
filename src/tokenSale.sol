// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

contract TokenSale is ReentrancyGuard {
    using Math for uint256;

    // token put up for sales
    IERC20 public immutable token;

    //stablecoin
    IERC20 public immutable stableCoin;

    //price rate of a token in eth
    uint256 public immutable ethRate;

    //price rate of a token in stable coin
    uint256 public immutable stableRate;

    //maximum funds raise
    uint256 immutable cap;

    //sales window duration
    uint256 immutable salesPeriod;

    //smallest amount allowed per buyer
    uint256 public immutable minimumContribution;

    //largest amount per buyer
    uint256 public immutable maximumContribution;

    //address where funds are collected
    address public immutable wallet;

    //lock duration56
    uint256 public immutable lockPeriod;

    //contract Owner
    address public immutable owner;

    //sales window start time
    uint256 public startTime;

    //sales window close time
    uint256 public endTime;

    bool public isSaleOpen;

    //use to track how many tokens each address bought
    mapping(address => uint256) public tokensBought;

    event tokenPurchased(address indexed buyer, uint256 amount);
    event tokenLocked(address indexed buyer, uint256 amount);
    event tokenClaimed(address indexed buyer, uint256 amount);

    error salesClosed();
    error belowMinimumContribution();
    error aboveMaximumContribution();
    error invalidAddress();
    error onlyOwnerAction();
    error salesActive();
    error salesNotActive();
    error InsufficientBalance();
    error transferFailed();

    modifier onlyWhileOpen() {
        if (!isSaleOpen || block.timestamp < startTime || block.timestamp > endTime) revert salesClosed();
        _;
    }

    modifier validContribution() {
        if (msg.value < minimumContribution) revert belowMinimumContribution();
        if (msg.value > maximumContribution) revert aboveMaximumContribution();
        _;
    }

    modifier onlyOwner() {
        if (owner != msg.sender) revert onlyOwnerAction();
        _;
    }

    constructor(
        address _tokenAddr,
        address _stableAddr,
        uint256 _cap,
        uint256 _salesPeriod,
        uint256 _minimumContribution,
        uint256 _maxContribution,
        address _wallet,
        uint256 _lockPeriod,
        address _owner,
        uint256 _ethRate,
        uint256 _stableRate
    ) ReentrancyGuard() {
        if (_tokenAddr == address(0) || _stableAddr == address(0) || _wallet == address(0) || _owner == address(0)) {
            revert invalidAddress();
        }

        token = IERC20(_tokenAddr);
        stableCoin = IERC20(_stableAddr);
        cap = _cap;
        salesPeriod = _salesPeriod;
        minimumContribution = _minimumContribution;
        maximumContribution = _maxContribution;
        lockPeriod = _lockPeriod;
        owner = _owner;
        wallet = _wallet;
        ethRate = _ethRate;
        stableRate = _stableRate;
    }

    //==== Sale Controls ====//
    function startSale() external onlyOwner {
        if (isSaleOpen) revert salesActive();

        startTime = block.timestamp;
        endTime = startTime + salesPeriod;
        isSaleOpen = true;
    }

    function endSale() external onlyOwner {
        if (!isSaleOpen) revert salesNotActive();
        isSaleOpen = false;
    }

    function buyTokenWithEth() external payable nonReentrant onlyWhileOpen validContribution {
        uint256 amount = msg.value;
        uint256 tokenToBuy = (amount * ethRate) / 1e18;

        if (token.balanceOf(address(this)) <= tokenToBuy) revert InsufficientBalance();

        tokensBought[msg.sender] += tokenToBuy;

        token.transfer(msg.sender, tokenToBuy);

        (bool success,) = wallet.call{value: amount}("");
        if (!success) revert transferFailed();

        emit tokenPurchased(msg.sender, tokenToBuy);
    }

    function buyTokenWithStableCoin(uint256 amount) external nonReentrant onlyWhileOpen {
        if (amount < minimumContribution) revert belowMinimumContribution();
        if (amount > maximumContribution) revert aboveMaximumContribution();

        uint256 tokenToBuy = (amount * stableRate) / 1e18;

        if (token.balanceOf(address(this)) <= tokenToBuy) revert InsufficientBalance();

        require(stableCoin.transferFrom(msg.sender, wallet, amount), "Transaction Failed");
        tokensBought[msg.sender] += tokenToBuy;

        token.transfer(msg.sender, tokenToBuy);

        emit tokenPurchased(msg.sender, tokenToBuy);
    }
}
