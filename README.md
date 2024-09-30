# TimeLockedEscrow

## Overview

`TimeLockedEscrow` is a smart contract implemented on Ethereum that allows a buyer to deposit ERC20 tokens, which a seller can withdraw after a 3-day timelock. This contract is designed to facilitate secure and trustless transactions between two parties.

## Features

- **ERC-20 Compliance**: The contract is compatible with any standard ERC-20 token.
- **Timelock**: Ensures that the tokens can only be withdrawn by the seller after a 3-day period.
- **Security**: Implements `ReentrancyGuard` to prevent reentrancy attacks and uses `SafeERC20` for safe token transfers.

## Technology

The contract is implemented using Solidity 0.8.20 and relies on OpenZeppelin's contracts for enhanced security and standard functionality.

## Getting Started

### Prerequisites

- Node.js and npm
- Foundry (for local deployment and testing)

### Installation

1. Install Foundry if it's not already installed:

   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. Clone the repository:

   ```bash
   git clone https://github.com/jocoders/time-locked-escrow-token.git
   cd time-locked-escrow
   ```

3. Install dependencies:
   ```bash
   forge install
   ```

### Testing

Run tests using Foundry:

```bash
forge test
```

## Contributing

Contributions are welcome! Please fork the repository and open a pull request with your features or fixes.

## License

This project is unlicensed and free for use by anyone.
