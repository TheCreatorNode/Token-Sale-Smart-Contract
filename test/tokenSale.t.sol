// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TokenSale} from "../src/tokenSale.sol";

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract mockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }
}

contract testTokenSale is Test {
    TokenSale public sale;
    mockToken public saleToken;

    address public owner = makeAddr("owner");
    address public buyer = makeAddr("buyer");
    address public wallet = makeAddr("wallet");

    function setUp() public {
        vm.prank(owner);
        saleToken = new mockToken("sale Token", "SALE");

        //uint256 salesPeriod = 10 days;
        vm.prank(owner);
        sale = new TokenSale(
            address(saleToken), 1_000_000 ether, 10 days, 0.01 ether, 100_000 ether, wallet, 21 days, owner
        );

        vm.deal(buyer, 100_000 ether);
    }

    function testConstruction() public view {
        assertEq(address(sale.token()), address(saleToken));
        assertEq(address(sale.owner()), address(owner));
        assertEq(address(sale.wallet()), address(wallet));
    }

    function testConstructionInvalidAddress() public {
        vm.expectRevert(TokenSale.invalidAddress.selector);
        new TokenSale(address(0), 1_000_000 ether, 10 days, 0.01 ether, 100_000 ether, wallet, 21 days, owner);

        vm.expectRevert(TokenSale.invalidAddress.selector);
        new TokenSale(
            address(saleToken), 1_000_000 ether, 10 days, 0.01 ether, 100_000 ether, address(0), 21 days, owner
        );

        vm.expectRevert(TokenSale.invalidAddress.selector);
        new TokenSale(
            address(saleToken), 1_000_000 ether, 10 days, 0.01 ether, 100_000 ether, wallet, 21 days, address(0)
        );
    }

    function testStartSale() external {
        vm.prank(owner);
        sale.startSale();

        assertTrue(sale.isSaleOpen());
        assertEq(sale.startTime(), block.timestamp);
        assertEq(sale.endTime(), block.timestamp + 10 days);
    }

    function testExpectErrorEndSale() external {
        vm.prank(owner);
        vm.expectRevert(TokenSale.salesNotActive.selector);
        sale.endSale();

        assertFalse(sale.isSaleOpen());
    }

    function testPrankBuyerToCallStartSale() external {
        vm.prank(buyer);
        vm.expectRevert(TokenSale.onlyOwnerAction.selector);
        sale.startSale();
    }
}
