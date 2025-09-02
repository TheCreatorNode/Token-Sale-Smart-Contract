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
    mockToken public stableCoin;

    address public owner = makeAddr("owner");
    address public buyer = makeAddr("buyer");
    address public walletAddr = makeAddr("wallet");

    function setUp() public {
        stableCoin = new mockToken("mockStableCoin", "MSC");
        // vm.prank(owner);
        saleToken = new mockToken("sale Token", "SALE");

        //uint256 salesPeriod = 10 days;
        vm.prank(owner);
        sale = new TokenSale(
            address(saleToken),
            address(stableCoin),
            1_000_000 ether,
            10 days,
            1 ether,
            100_000 ether,
            walletAddr,
            21 days,
            owner,
            100,
            1
        );

        vm.deal(buyer, 200_000 ether);

        //mint sale token to contract
        saleToken.mint(address(sale), 1_000_00 * 1e18);
    }

    function testConstruction() public view {
        assertEq(address(sale.token()), address(saleToken));
        assertEq(address(sale.stableCoin()), address(stableCoin));
        assertEq(address(sale.owner()), owner);
        assertEq(address(sale.wallet()), walletAddr);
    }

    function testConstructionInvalidAddress() public {
        vm.expectRevert(TokenSale.invalidAddress.selector);
        new TokenSale(
            address(0),
            address(stableCoin),
            1_000_000 ether,
            10 days,
            1 ether,
            100_000 ether,
            walletAddr,
            21 days,
            owner,
            100,
            1
        );

        vm.expectRevert(TokenSale.invalidAddress.selector);
        new TokenSale(
            address(saleToken),
            address(stableCoin),
            1_000_000 ether,
            10 days,
            1 ether,
            100_000 ether,
            address(0),
            21 days,
            owner,
            100,
            1
        );

        vm.expectRevert(TokenSale.invalidAddress.selector);
        new TokenSale(
            address(saleToken),
            address(stableCoin),
            1_000_000 ether,
            10 days,
            1 ether,
            100_000 ether,
            walletAddr,
            21 days,
            address(0),
            100,
            1
        );
        vm.expectRevert(TokenSale.invalidAddress.selector);
        new TokenSale(
            address(saleToken),
            address(0),
            1_000_000 ether,
            10 days,
            1 ether,
            100_000 ether,
            walletAddr,
            21 days,
            owner,
            100,
            1
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

    function testBuyTokenWithEth() public {
        vm.prank(owner);
        sale.startSale();

        vm.deal(buyer, 100 ether);

        uint256 balanceBefore = sale.wallet().balance;

        vm.prank(buyer);
        sale.buyTokenWithEth{value: 10 ether}();

        uint256 balanceAfter = sale.wallet().balance;

        assertEq(balanceAfter, balanceBefore + 10 ether);
        assertEq(sale.tokensBought(buyer), 1000);
        assertEq(saleToken.balanceOf(buyer), 1000);
    }

    function testBuyTokenWithStableCoin() external {
        vm.prank(owner);
        sale.startSale();

        stableCoin.mint(buyer, 1000 * 1e18);
        vm.prank(buyer);
        stableCoin.approve(address(sale), 1000 * 1e18);
        uint256 balanceBefore = stableCoin.balanceOf(sale.wallet());

        vm.prank(buyer);
        sale.buyTokenWithStableCoin(100 * 1e18);

        uint256 balanceAfter = stableCoin.balanceOf(sale.wallet());

        assertEq(balanceAfter, balanceBefore + 100 * 1e18);
    }

    function testBuyTokenWithEthRevertSaleClose() public {
        vm.prank(buyer);
        vm.expectRevert(TokenSale.salesClosed.selector);
        sale.buyTokenWithEth();
    }

    function testBuyTokenWithRevertAboveMaximumContribution() public {
        vm.prank(owner);
        sale.startSale();

        vm.deal(buyer, 200_000 ether);
        vm.prank(buyer);
        vm.expectRevert(TokenSale.aboveMaximumContribution.selector);
        sale.buyTokenWithEth{value: 100_101 ether}();
    }

    function testBuyTokenWithRevertBelowMinimumContribution() public {
        vm.prank(owner);
        sale.startSale();

        vm.deal(buyer, 200_000 ether);
        vm.prank(buyer);
        vm.expectRevert(TokenSale.belowMinimumContribution.selector);
        sale.buyTokenWithEth{value: 0.001 ether}();
    }
}
