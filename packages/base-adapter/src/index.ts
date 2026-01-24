import { createAppKit } from '@reown/appkit'
import { EthersAdapter } from '@reown/appkit-adapter-ethers'
import { baseSepolia } from '@reown/appkit/networks'
import { BrowserProvider, Contract, formatEther, parseEther } from 'ethers'

const projectId = process.env.NEXT_PUBLIC_REOWN_PROJECT_ID || ''

const metadata = {
    name: 'ChainVote',
    description: 'Decentralized Voting on Base',
    url: typeof window !== 'undefined' ? window.location.origin : '',
    icons: ['https://avatars.githubusercontent.com/u/37784886']
}

export const appKit = createAppKit({
    adapters: [new EthersAdapter()],
    networks: [baseSepolia],
    metadata,
    projectId,
    features: {
        analytics: true
    }
})

export interface WalletState {
    address: string | null
    chainId: number | null
    balance: string | null
    isConnected: boolean
}

export class BaseWalletAdapter {
    private provider: BrowserProvider | null = null

    async connect(): Promise<WalletState> {
        await appKit.open()
        return this.getState()
    }

    async disconnect(): Promise<void> {
        await appKit.disconnect()
    }

    async getState(): Promise<WalletState> {
        const walletInfo = appKit.getWalletInfo()
        const account = appKit.getAddress()
        const chainId = appKit.getChainId()

        if (!account) {
            return {
                address: null,
                chainId: null,
                balance: null,
                isConnected: false
            }
        }

        let balance = null
        try {
            const provider = await this.getProvider()
            const balanceWei = await provider.getBalance(account)
            balance = formatEther(balanceWei)
        } catch (error) {
            console.error('Error fetching balance:', error)
        }

        return {
            address: account,
            chainId: chainId || null,
            balance,
            isConnected: true
        }
    }

    async getProvider(): Promise<BrowserProvider> {
        if (!this.provider) {
            const walletProvider = appKit.getWalletProvider()
            if (!walletProvider) {
                throw new Error('No wallet provider available')
            }
            this.provider = new BrowserProvider(walletProvider)
        }
        return this.provider
    }

    async getSigner() {
        const provider = await this.getProvider()
        return provider.getSigner()
    }

    async switchNetwork(chainId: number): Promise<void> {
        await appKit.switchNetwork(chainId)
    }

    onAccountChange(callback: (account: string | null) => void): void {
        appKit.subscribeAccount((account) => {
            callback(account.address || null)
        })
    }

    onChainChange(callback: (chainId: number | null) => void): void {
        appKit.subscribeChain((chain) => {
            callback(chain.id || null)
        })
    }
}

export const baseWallet = new BaseWalletAdapter()

// Contract interaction helpers
export interface VotingContractConfig {
    address: string
    abi: any[]
}

export class VotingContract {
    private contract: Contract | null = null
    private config: VotingContractConfig

    constructor(config: VotingContractConfig) {
        this.config = config
    }

    async getContract(): Promise<Contract> {
        if (!this.contract) {
            const signer = await baseWallet.getSigner()
            this.contract = new Contract(this.config.address, this.config.abi, signer)
        }
        return this.contract
    }

    async createProposal(
        title: string,
        description: string,
        options: string[],
        duration: number
    ): Promise<string> {
        const contract = await this.getContract()
        const tx = await contract.createProposal(title, description, options, duration)
        const receipt = await tx.wait()
        return receipt.hash
    }

    async vote(proposalId: number, optionIndex: number): Promise<string> {
        const contract = await this.getContract()
        const tx = await contract.vote(proposalId, optionIndex)
        const receipt = await tx.wait()
        return receipt.hash
    }

    async getProposal(proposalId: number): Promise<any> {
        const contract = await this.getContract()
        return contract.getProposal(proposalId)
    }

    async getVoteCount(proposalId: number, optionIndex: number): Promise<number> {
        const contract = await this.getContract()
        const count = await contract.getVoteCount(proposalId, optionIndex)
        return Number(count)
    }

    async getUserVote(proposalId: number, address: string): Promise<boolean> {
        const contract = await this.getContract()
        return contract.getUserVote(proposalId, address)
    }

    async getProposalCount(): Promise<number> {
        const contract = await this.getContract()
        const count = await contract.proposalCount()
        return Number(count)
    }
}

export { formatEther, parseEther }
