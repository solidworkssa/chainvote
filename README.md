# 01-chainvote - Base Native Architecture

> **Built for the Base Superchain & Stacks Bitcoin L2**

This project is architected to be **Base-native**: prioritizing onchain identity, low-latency interactions, and indexer-friendly data structures.

## 🔵 Base Native Features
- **Smart Account Ready**: Compatible with ERC-4337 patterns.
- **Identity Integrated**: Designed to resolve Basenames and store social metadata.
- **Gas Optimized**: Uses custom errors and batched call patterns for L2 efficiency.
- **Indexer Friendly**: Emits rich, indexed events for Subgraph data availability.

## 🟠 Stacks Integration
- **Bitcoin Security**: Leverages Proof-of-Transfer (PoX) via Clarity contracts.
- **Post-Condition Security**: Strict asset movement checks.

---
# ChainVote

A decentralized voting system deployed on Base (EVM) and Stacks blockchains.

## Features

- Create voting proposals with title, description, and options
- Vote on active proposals
- View real-time vote tallies
- Dual-chain support: Base (Solidity) and Stacks (Clarity v4)
- Wallet integration: Reown for Base, @stacks/connect for Stacks

## Architecture

```
chainvote/
├── apps/
│   └── web/                 # Next.js frontend
├── contracts/
│   ├── base/               # Solidity contracts (Foundry)
│   └── stacks/             # Clarity v4 contracts
├── packages/
│   ├── shared/             # Common UI components & types
│   ├── base-adapter/       # Base wallet & contract utils
│   └── stacks-adapter/     # Stacks wallet & contract utils
├── scripts/                # Deploy & utility scripts
└── tests/                  # E2E tests
```

## Prerequisites

- Node.js >= 18
- pnpm >= 8
- Foundry (for Base contracts)
- Clarinet (for Stacks contracts)

## Installation

```bash
pnpm install
```

## Environment Variables

Create `.env.local` in `apps/web/`:

```env
# Base (EVM)
NEXT_PUBLIC_BASE_RPC_URL=https://sepolia.base.org
NEXT_PUBLIC_BASE_CHAIN_ID=84532
NEXT_PUBLIC_VOTING_CONTRACT_ADDRESS=0x...

# Stacks
NEXT_PUBLIC_STACKS_NETWORK=testnet
NEXT_PUBLIC_STACKS_CONTRACT_ADDRESS=ST...voting
NEXT_PUBLIC_STACKS_CONTRACT_NAME=voting

# Reown (WalletConnect)
NEXT_PUBLIC_REOWN_PROJECT_ID=your_project_id
```

## Development

```bash
# Start development server
pnpm dev

# Build all packages
pnpm build

# Run tests
pnpm test

# Run E2E tests
pnpm test:e2e
```

## Contract Development

### Base (Solidity)

```bash
cd contracts/base

# Compile
forge build

# Test
forge test

# Deploy to Base Sepolia
forge script script/Deploy.s.sol --rpc-url $BASE_RPC_URL --broadcast --verify
```

### Stacks (Clarity)

```bash
cd contracts/stacks

# Check syntax
clarinet check

# Test
clarinet test

# Deploy to testnet
clarinet deploy --testnet
```

## Contract Specifications

### Base Contract (Solidity)

**Storage:**
- `proposals` mapping: proposalId => Proposal struct
- `votes` mapping: proposalId => voter => optionIndex
- `proposalCount` counter

**Functions:**
- `createProposal(title, description, options, duration)` - Create new proposal
- `vote(proposalId, optionIndex)` - Cast vote
- `getProposal(proposalId)` - Read proposal data
- `getVoteCount(proposalId, optionIndex)` - Get vote tally

**Events:**
- `ProposalCreated(proposalId, creator, title)`
- `VoteCast(proposalId, voter, optionIndex)`

### Stacks Contract (Clarity v4)

**Data:**
- `proposals` map: uint => {title, creator, end-block, options}
- `votes` map: {proposal-id, voter} => option-index
- `vote-counts` map: {proposal-id, option} => count
- `proposal-nonce` var

**Public Functions:**
- `create-proposal` - Create new proposal
- `cast-vote` - Submit vote

**Read-Only Functions:**
- `get-proposal` - Fetch proposal details
- `get-vote-count` - Get vote tally
- `get-user-vote` - Check if user voted

## Testing

### Contract Tests

```bash
# Base contracts
pnpm test:base

# Stacks contracts
pnpm test:stacks
```

### E2E Tests

Uses Playwright with mock wallet strategies:

```bash
pnpm test:e2e
```

Test scenarios:
- Connect Base wallet
- Connect Stacks wallet
- Create proposal on both chains
- Vote on proposal
- View results

## Deployment

### Base Testnet

1. Set environment variables:
```bash
export BASE_RPC_URL=https://sepolia.base.org
export PRIVATE_KEY=your_private_key
```

2. Deploy:
```bash
pnpm deploy:base
```

3. Verify contract on BaseScan

### Stacks Testnet

1. Configure `Clarinet.toml` with testnet settings

2. Deploy:
```bash
pnpm deploy:stacks
```

3. Note contract address for frontend config

## Proof of Functionality

### Base Testnet
- Contract: `0x...` (Base Sepolia)
- Example TX: `0x...` (Proposal creation)
- Explorer: [BaseScan](https://sepolia.basescan.org/address/0x...)

### Stacks Testnet
- Contract: `ST...voting`
- Example TX: `0x...` (Vote cast)
- Explorer: [Stacks Explorer](https://explorer.hiro.so/txid/0x...?chain=testnet)

## Known Limitations

- No proposal editing after creation
- Single vote per address (no vote changing)
- No vote delegation
- Simple majority counting (no weighted votes)

## Future Improvements

- Quadratic voting
- Vote delegation
- Proposal amendments
- Time-weighted voting power
- Multi-sig proposal creation
- IPFS metadata storage

## License

MIT

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md)

## Security

See [SECURITY.md](./SECURITY.md)
