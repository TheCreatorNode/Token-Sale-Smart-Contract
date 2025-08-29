// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

import {safeMath} from "lib/openzeppelin-contracts/contracts/utils/Math.sol";

contract tokenSale is ReentrancyGuard {
    using safeMath for uint256;

    // token put up for sales
    IERC20 public token;

    //price rate of a token in eth
    uint256 public tokenRate;

    //maximum funds raise
    uint256 immutable CAP;

    //sales window duration
    uint256 immutable salesPeriod;

    //sales window close time
    uint256 immutable endTime;

    //smallest amount allowed per buyer
    uint256 public minimumContribution;

    //largest amount per buyer
    uint256 public maximumContribution;

    //address where funds are collected
    address immutable wallet;

    //lock duration56
    uint256 public immutable lockPeriod;

    event tokenPurchased(address buyer, uint256 amount);
    event tokenLocked(address buyer, uint256 amount);
    event tokenClaimed(uint256 amount);
}
