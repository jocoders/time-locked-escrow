// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Time-Locked Escrow for ERC20 Tokens
/// @author Evgeniy Kireev
/// @notice This contract allows a buyer to deposit ERC20 tokens that a seller can withdraw after a 3-day timelock.
/// @dev This contract uses ReentrancyGuard to prevent reentrancy attacks and SafeERC20 for safe token transfers.
/// @custom:security-standard Follows OpenZeppelin's security standards for token handling and reentrancy.
contract TimeLockedEscrow is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Deal {
        address buyer;
        address seller;
        uint256 amount;
        uint256 depositTime;
        bool isWithdrawn;
    }

    mapping(uint256 => Deal) public deals;
    uint256 private dealCounter;
    uint256 private constant TIMELOCK = 3 days;

    event Deposit(uint256 escrowId, address indexed buyer, address indexed seller, uint256 amount);
    event Withdraw(uint256 escrowId, address indexed seller, uint256 amount);
    event Refund(uint256 escrowId, address indexed buyer, uint256 amount);

    /// @notice Deposits `amount` of `token` to the escrow, locked for 3 days before the seller can withdraw.
    /// @dev Emits a Deposit event upon successful deposit.
    /// @param token The ERC20 token to deposit.
    /// @param seller The address of the token recipient after the timelock.
    /// @param amount The amount of tokens to deposit.
    function deposit(IERC20 token, address seller, uint256 amount) external nonReentrant {
        require(seller != address(0), "Seller address cannot be zero");
        require(amount > 0, "Amount must be greater than zero");

        deals[dealCounter] =
            Deal({buyer: msg.sender, seller: seller, amount: amount, depositTime: block.timestamp, isWithdrawn: false});

        uint256 initialBalance = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 finalBalance = token.balanceOf(address(this));

        uint256 receivedAmount = finalBalance - initialBalance;
        require(receivedAmount >= amount, "Incorrect token transfer amount");

        emit Deposit(dealCounter, msg.sender, seller, amount);
        dealCounter++;
    }

    /// @notice Allows the seller to withdraw the tokens after the 3-day timelock.
    /// @dev Emits a Withdraw event upon successful withdrawal.
    /// @param token The ERC20 token to withdraw.
    /// @param dealId The ID of the escrow deal.
    function withdraw(IERC20 token, uint256 dealId) external nonReentrant {
        Deal storage deal = deals[dealId];
        require(deal.seller == msg.sender, "Only seller can withdraw");
        require(!deal.isWithdrawn, "Tokens already withdrawn");
        require(block.timestamp >= deal.depositTime + TIMELOCK, "Withdrawal locked for 3 days");

        deal.isWithdrawn = true;
        token.safeTransfer(msg.sender, deal.amount);

        emit Withdraw(dealId, msg.sender, deal.amount);
    }

    /// @notice Allows the buyer to request a refund before the timelock expires.
    /// @dev Emits a Refund event upon successful refund.
    /// @param token The ERC20 token to refund.
    /// @param dealId The ID of the escrow deal.
    function refund(IERC20 token, uint256 dealId) external nonReentrant {
        Deal storage deal = deals[dealId];
        require(deal.buyer == msg.sender, "Only buyer can request refund");
        require(!deal.isWithdrawn, "Tokens already withdrawn");
        require(block.timestamp < deal.depositTime + TIMELOCK, "Refund window has closed");

        deal.isWithdrawn = true;
        token.safeTransfer(msg.sender, deal.amount);

        emit Refund(dealId, msg.sender, deal.amount);
    }
}
