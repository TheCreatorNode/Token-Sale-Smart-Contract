// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

contract tokenSale is ReentrancyGuard {
    using Math for uint256;

    // token put up for sales
    IERC20 public token;

    //price rate of a token in eth
    uint256 public tokenRate;

    //maximum funds raise
    uint256 immutable CAP;

    //sales window duration
    uint256 immutable salesPeriod;

    //sales window start time
    uint256 public startTime;

    //sales window close time
    uint256 public endTime;

    //smallest amount allowed per buyer
    uint256 public minimumContribution;

    //largest amount per buyer
    uint256 public maximumContribution;

    //address where funds are collected
    address immutable wallet;

    //lock duration56
    uint256 public immutable lockPeriod;

    //contract Owner
    address public owner;

    bool public isSaleOpen;

    //use to track how many tokens each address bought
    mapping(address => uint256) public tokensBought;

    event tokenPurchased(address buyer, uint256 amount);
    event tokenLocked(address buyer, uint256 amount);
    event tokenClaimed(uint256 amount);

    error salesClosed();
    error belowMinimumCost();
    error maxTokenPassed();
    error invalidAddress();
    error onlyOwnerAction();

    modifier onlyWhileOpen(uint256 _startTime, uint256 _endTime) {
        if (block.timestamp < _startTime || block.timestamp > _endTime) revert salesClosed();
        _;
    }

    modifier cost(uint256 _amount) {
        if (_amount < 0.01 ether) revert belowMinimumCost();
        _;
    }

    modifier withinLimit(uint256 _token) {
        if (_token > 100) revert maxTokenPassed();
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
        if (_tokenAddr == address(0)) revert invalidAddress();
        token = IERC20(_tokenAddr);
        CAP = _CAP;
        salesPeriod = _salesPeriod;
        endTime = startTime + salesPeriod;
        minimumContribution = _minimumContribution;
        maximumContribution = _maxContribution;
        lockPeriod = _lockPeriod;
        owner = _owner;
        wallet = _wallet;
    }

    function startSale() public onlyOwner {
        isSaleOpen = true;
        startTime = block.timestamp;
    }

    function endSale() public onlyOwner {
        isSaleOpen = false;
    }
}
