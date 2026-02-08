# ChainVote - Decentralized Voting Platform

A production-ready, multi-chain decentralized voting platform built on Base (EVM) and Stacks blockchains. ChainVote enables transparent, secure, and verifiable on-chain governance with support for multiple voting mechanisms.

## Features

### Core Functionality
- **Multi-Chain Support**: Seamlessly interact with both Base (EVM) and Stacks blockchains
- **Multiple Voting Mechanisms**:
  - Simple voting (one address = one vote)
  - Weighted voting (based on token/STX balance)
  - Quadratic voting (for more democratic outcomes)
- **Vote Delegation**: Delegate your voting power to trusted representatives
- **Quorum Requirements**: Set minimum participation thresholds for proposals
- **Proposal Management**: Create, vote on, cancel, and end proposals
- **Real-time Updates**: Live vote counting and proposal status tracking

### Security Features
- OpenZeppelin security standards (Ownable, ReentrancyGuard, Pausable)
- Custom error messages for gas efficiency
- Comprehensive input validation
- Access control for sensitive operations
- Emergency pause functionality

## Technology Stack

### Frontend
- **Framework**: Next.js 14+ with App Router
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **UI Components**: Custom components with Framer Motion animations
- **State Management**: React Hooks

### Smart Contracts
- **Base (EVM)**: Solidity ^0.8.20 with OpenZeppelin
- **Stacks**: Clarity v2
- **Development**: Foundry (Base), Clarinet (Stacks)

### Wallet Integration
- **Base**: MetaMask, Coinbase Wallet, WalletConnect
- **Stacks**: Leather, Xverse

## Getting Started

### Prerequisites
- Node.js 18+ and pnpm
- Foundry (for Base contracts)
- Clarinet (for Stacks contracts)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/solidworkssa/chainvote.git
cd chainvote
```

2. **Install dependencies**
```bash
pnpm install
```

3. **Set up environment variables**
```bash
cp .env.example .env.local
```

Edit `.env.local` and add your configuration:
```env
# Base Contract Address
NEXT_PUBLIC_BASE_CONTRACT_ADDRESS=0x...

# Stacks Contract
NEXT_PUBLIC_STACKS_CONTRACT_ADDRESS=SP...
NEXT_PUBLIC_STACKS_CONTRACT_NAME=chainvote-01

# Network Configuration
NEXT_PUBLIC_BASE_CHAIN_ID=8453
NEXT_PUBLIC_STACKS_NETWORK=mainnet

# Optional: Analytics
NEXT_PUBLIC_ANALYTICS_ID=your-analytics-id
```

4. **Run the development server**
```bash
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000) to see the application.

## Smart Contract Deployment

### Base (EVM) Deployment

1. **Compile contracts**
```bash
cd contracts/base
forge build
```

2. **Run tests**
```bash
forge test
```

3. **Deploy to Base**
```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url base --broadcast --verify
```

### Stacks Deployment

1. **Check contract**
```bash
cd contracts/stacks
clarinet check
```

2. **Run tests**
```bash
clarinet test
```

3. **Deploy to Stacks Mainnet**
```bash
clarinet deployments apply --mainnet
```

## Usage

### Creating a Proposal

1. Connect your wallet (Base or Stacks)
2. Click "Create Proposal"
3. Fill in the proposal details:
   - Title and description
   - Voting options (up to 20)
   - Duration (1 hour to 30 days)
   - Voting mechanism (Simple, Weighted, or Quadratic)
   - Optional: Set quorum requirement
4. Submit the transaction

### Voting on a Proposal

1. Browse active proposals
2. Click on a proposal to view details
3. Select your preferred option
4. Submit your vote
5. Wait for transaction confirmation

### Delegating Your Vote

1. Navigate to an active proposal
2. Click "Delegate Vote"
3. Enter the delegate's address
4. Confirm the delegation

## Project Structure

```
chainvote/
├── apps/
│   └── web/                    # Next.js frontend application
│       ├── app/                # App router pages
│       ├── components/         # React components
│       ├── hooks/              # Custom React hooks
│       └── lib/                # Utility functions
├── contracts/
│   ├── base/                   # Solidity contracts
│   │   ├── src/                # Contract source files
│   │   ├── test/               # Contract tests
│   │   └── script/             # Deployment scripts
│   └── stacks/                 # Clarity contracts
│       ├── contracts/          # Contract source files
│       ├── tests/              # Contract tests
│       └── settings/           # Network configurations
├── packages/
│   ├── base-adapter/           # Base wallet adapter
│   ├── stacks-adapter/         # Stacks wallet adapter
│   └── shared/                 # Shared utilities and types
└── docs/                       # Documentation

```

## API Reference

### Base Contract (ChainVote.sol)

#### Create Proposal
```solidity
function createProposal(
    string memory _title,
    string memory _description,
    string[] memory _options,
    uint256 _duration,
    VotingMechanism _mechanism,
    uint256 _quorum
) external returns (uint256)
```

#### Cast Vote
```solidity
function vote(uint256 _proposalId, uint256 _optionIndex) external
```

#### Delegate Vote
```solidity
function delegateVote(uint256 _proposalId, address _delegate) external
```

### Stacks Contract (chainvote-01.clar)

#### Create Proposal
```clarity
(create-proposal 
    (title (string-ascii 256))
    (description (string-utf8 1024))
    (options (list 10 (string-utf8 256)))
    (duration uint)
    (mechanism uint)
    (quorum uint))
```

#### Cast Vote
```clarity
(cast-vote (proposal-id uint) (option-index uint))
```

## Testing

### Frontend Tests
```bash
pnpm test
```

### Contract Tests (Base)
```bash
cd contracts/base
forge test -vvv
```

### Contract Tests (Stacks)
```bash
cd contracts/stacks
clarinet test
```

## Security

### Audits
- Smart contracts have been designed with security best practices
- Uses OpenZeppelin audited libraries
- Comprehensive test coverage

### Bug Bounty
We take security seriously. If you discover a security vulnerability, please email security@chainvote.example.com.

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Documentation**: [docs.chainvote.example.com](https://docs.chainvote.example.com)
- **Discord**: [Join our community](https://discord.gg/chainvote)
- **Twitter**: [@chainvote](https://twitter.com/chainvote)
- **Email**: support@chainvote.example.com

## Roadmap

- [x] Multi-chain voting (Base + Stacks)
- [x] Multiple voting mechanisms
- [x] Vote delegation
- [x] Quorum requirements
- [ ] Token-gated proposals
- [ ] Snapshot integration
- [ ] Mobile app
- [ ] DAO treasury integration
- [ ] Cross-chain proposal mirroring
- [ ] Advanced analytics dashboard

## Acknowledgments

- OpenZeppelin for security libraries
- Stacks Foundation for Clarity development tools
- Base team for EVM infrastructure
- Our amazing community of contributors

---

Built with ❤️ by the Multi-Chain dApp Team
