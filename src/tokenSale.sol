// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

contract TokenSale is ReentrancyGuard {
    using Math for uint256;

    // token put up for sales
    IERC20 public immutable token;

    //price rate of a token in eth
    uint256 public immutable tokenRate;

    //maximum funds raise
    uint256 immutable CAP;

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

    modifier onlyWhileOpen(uint256 _startTime, uint256 _endTime) {
        if (!isSaleOpen || block.timestamp < _startTime || block.timestamp > _endTime) revert salesClosed();
        _;
    }

    modifier validContribution(uint256 _amount) {
        if (_amount < minimumContribution) revert belowMinimumContribution();
        if (_amount > maximumContribution) revert aboveMaximumContribution();
        _;
    }

    modifier onlyOwner() {
        if (owner != msg.sender) revert onlyOwnerAction();
        _;
    }

    constructor(
        address _tokenAddr,
        uint256 _CAP,
        uint256 _salesPeriod,
        uint256 _minimumContribution,
        uint256 _maxContribution,
        address _wallet,
        uint256 _lockPeriod,
        address _owner
    ) ReentrancyGuard() {
        if (_tokenAddr == address(0) || _wallet == address(0) || _owner == address(0)) revert invalidAddress();

        token = IERC20(_tokenAddr);
        CAP = _CAP;
        salesPeriod = _salesPeriod;
        minimumContribution = _minimumContribution;
        maximumContribution = _maxContribution;
        lockPeriod = _lockPeriod;
        owner = _owner;
        wallet = _wallet;
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
}
