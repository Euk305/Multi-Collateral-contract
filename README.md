# Multi-Collateral Stablecoin with BTC Backing

A decentralized stablecoin system built on Clarity that uses multiple collateral types with Bitcoin as the primary backing.

## Overview

This project implements a collateralized debt position (CDP) system similar to MakerDAO's DAI, but built specifically for the Stacks ecosystem with Bitcoin as the primary collateral. Users can lock collateral in vaults to generate stablecoin tokens, which maintain a soft peg to the US dollar.

## Key Features

- **Bitcoin-First Collateralization**: Leverages Bitcoin as the primary backing asset through Stacks' Bitcoin integration
- **Multi-Collateral Support**: Accepts various assets as collateral (STX, sBTC, and other Clarity-based tokens)
- **Dynamic Risk Parameters**: Adjustable liquidation thresholds based on market conditions
- **Governance System**: Parameter adjustments through governance mechanisms
- **Stability Mechanisms**: Incentives and fees that help maintain the dollar peg
- **Liquidation Engine**: Protocol for handling undercollateralized positions

## System Architecture

### Core Components

1. **Vaults**: Where users lock collateral and generate stablecoin
2. **Collateral Types**: Different assets accepted as collateral, each with unique risk parameters
3. **Price Oracles**: Provide reliable price feeds for calculating collateralization ratios
4. **Stability Module**: Handles stability fees and surplus distribution
5. **Liquidation Module**: Processes for liquidating undercollateralized vaults
6. **Governance Module**: Mechanisms for updating system parameters

### Smart Contracts

The system consists of the following Clarity smart contracts:

- `stablecoin.clar`: Core contract with CDP functionality
- `governance.clar`: Handles governance proposals and voting (future development)
- `oracle.clar`: Interface for price data feeds (future development)
- `auction.clar`: Handles liquidation auctions (future development)

## How It Works

### Creating a Vault

1. User selects a collateral type (BTC, STX, etc.)
2. User deposits collateral into a vault
3. Based on the current price and collateralization ratio, the system calculates how much stablecoin can be safely generated
4. User generates stablecoin against their collateral, creating a debt position

### Maintaining a Vault

- Users must maintain the minimum collateralization ratio for their vault's collateral type
- Stability fees accrue on outstanding debt over time
- Users can add more collateral or repay debt at any time

### Liquidation Process

1. If a vault's collateralization ratio falls below the liquidation ratio, it becomes eligible for liquidation
2. Liquidators repay the outstanding debt and receive the collateral at a discount (liquidation penalty)
3. The original vault owner receives any remaining collateral after the debt and penalty are covered

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) for local development and testing
- [Stacks Wallet](https://www.hiro.so/wallet) for interacting with the deployed contract

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/btc-backed-stablecoin.git
   cd btc-backed-stablecoin
   ```

2. Install dependencies:
   ```
   clarinet install
   ```

3. Run tests:
   ```
   clarinet test
   ```

### Deploying Locally

```
clarinet console
```

## Using the Contract

### Opening a Vault

```clarity
(contract-call? .stablecoin open-vault "BTC" u100000000 u50000000)
```
This opens a vault with 1 BTC as collateral and generates 50,000 stablecoin tokens.

### Adding Collateral

```clarity
(contract-call? .stablecoin deposit-collateral u1 "BTC" u50000000)
```
This adds 0.5 BTC to vault #1.

### Generating More Stablecoin

```clarity
(contract-call? .stablecoin generate-stablecoin u1 "BTC" u25000000)
```
This generates an additional 25,000 stablecoin tokens from vault #1.

### Repaying Debt

```clarity
(contract-call? .stablecoin repay-stablecoin u1 "BTC" u30000000)
```
This repays 30,000 stablecoin tokens to vault #1.

### Withdrawing Collateral

```clarity
(contract-call? .stablecoin withdraw-collateral u1 "BTC" u25000000)
```
This withdraws 0.25 BTC from vault #1.

## Risk Management

### Collateralization Ratios

The system uses different collateralization ratios for different collateral types based on their risk profile:

- BTC: 150% minimum collateralization ratio
- STX: 175% minimum collateralization ratio
- Other tokens: 200%+ minimum collateralization ratio

### Emergency Shutdown

In case of extreme market conditions or critical bugs, governance can trigger an emergency shutdown:

```clarity
(contract-call? .stablecoin set-liquidation-enabled false)
```

## Governance

System parameters can be adjusted through governance, including:

- Collateralization ratios
- Stability fees
- Debt ceilings
- Liquidation penalties
- Oracle sources

## Development Roadmap

### Phase 1: Core CDP Functionality (Current)
- Basic vault management
- BTC and STX collateral support
- Simple liquidation mechanisms

### Phase 2: Enhanced Features
- Multiple collateral types beyond BTC and STX
- Advanced liquidation auctions
- Stability fees and global settlement

### Phase 3: Governance and Scaling
- Decentralized governance system
- Layer 2 payment channel integration
- Cross-chain collateral support

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Inspired by MakerDAO's multi-collateral DAI system
- Built for the Stacks ecosystem
- Designed to leverage Bitcoin's security and liquidity
