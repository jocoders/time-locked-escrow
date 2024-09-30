// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {TimeLockedEscrow} from "../src/TimeLockedEscrow.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("MockToken", "MT") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract TimeLockedEscrowTest is Test {
    TimeLockedEscrow public escrowContract;
    MockERC20 public token;

    address buyer = address(0x1);
    address seller = address(0x2);
    address zeroAddress = address(0x0);
    uint256 erc20Amount = 500;

    event Deposit(uint256 escrowId, address indexed buyer, address indexed seller, uint256 amount);
    event Withdraw(uint256 escrowId, address indexed seller, uint256 amount);
    event Refund(uint256 escrowId, address indexed buyer, uint256 amount);

    function setUp() public {
        escrowContract = new TimeLockedEscrow();
        token = new MockERC20();
        token.mint(buyer, 1000);

        vm.deal(buyer, 10 ether);
        vm.deal(seller, 10 ether);
    }

    function testDeposit() public {
        vm.startPrank(buyer);
        token.approve(address(escrowContract), erc20Amount);

        vm.expectEmit();
        emit Deposit(0, buyer, seller, erc20Amount);
        escrowContract.deposit(token, seller, erc20Amount);
        vm.stopPrank();

        (address _buyer, address _seller, uint256 _amount,, bool _isWithdrawn) = escrowContract.deals(0);
        assertEq(_buyer, buyer);
        assertEq(_seller, seller);
        assertEq(_amount, erc20Amount);
        assertFalse(_isWithdrawn);
    }

    function testDepositWithZeroAmount() public {
        vm.expectRevert("Amount must be greater than zero");
        escrowContract.deposit(token, buyer, 0);
    }

    function testDepositWithZeroAddress() public {
        vm.expectRevert("Seller address cannot be zero");
        escrowContract.deposit(token, address(0), 100);
    }

    function testWithdraw() public {
        testDeposit();
        uint256 dealId = 0;

        vm.warp(block.timestamp + 3 days);

        vm.prank(seller);
        vm.expectEmit();
        emit Withdraw(dealId, seller, erc20Amount);
        escrowContract.withdraw(IERC20(address(token)), dealId);

        (,,,, bool _isWithdrawn) = escrowContract.deals(dealId);
        assertTrue(_isWithdrawn);

        vm.prank(seller);
        vm.expectRevert("Tokens already withdrawn");
        escrowContract.withdraw(IERC20(address(token)), dealId);
    }

    function testWithdrawBeforeTimelock() public {
        testDeposit();
        uint256 dealId = 0;

        vm.warp(block.timestamp + 1 days);
        vm.prank(seller);
        vm.expectRevert("Withdrawal locked for 3 days");
        escrowContract.withdraw(IERC20(address(token)), dealId);
    }

    function testWithdrawNotSeller() public {
        uint256 dealId = 0;
        vm.prank(seller);
        vm.expectRevert("Only seller can withdraw");
        escrowContract.withdraw(IERC20(address(token)), dealId);
    }

    function testRefund() public {
        testDeposit();
        uint256 dealId = 0;

        vm.warp(block.timestamp + 1 hours);
        vm.prank(buyer);
        vm.expectEmit();
        emit Refund(dealId, buyer, erc20Amount);
        escrowContract.refund(IERC20(address(token)), dealId);

        (,,,, bool _isWithdrawn) = escrowContract.deals(dealId);
        assertTrue(_isWithdrawn);

        vm.prank(buyer);
        vm.expectRevert("Tokens already withdrawn");
        escrowContract.refund(IERC20(address(token)), dealId);
    }

    function testRefundBeforeTimelock() public {
        testDeposit();
        uint256 dealId = 0;

        vm.warp(block.timestamp + 4 days);
        vm.prank(buyer);
        vm.expectRevert("Refund window has closed");
        escrowContract.refund(IERC20(address(token)), dealId);
    }
}
