import { AppConfig, UserSession, showConnect } from '@stacks/connect'
import {
    makeContractCall,
    broadcastTransaction,
    AnchorMode,
    PostConditionMode,
    stringAsciiCV,
    stringUtf8CV,
    listCV,
    uintCV,
    principalCV,
    callReadOnlyFunction,
    cvToJSON,
    ClarityValue
} from '@stacks/transactions'
import { StacksTestnet, StacksMainnet, StacksNetwork } from '@stacks/network'

const appConfig = new AppConfig(['store_write', 'publish_data'])
export const userSession = new UserSession({ appConfig })

export interface StacksWalletState {
    address: string | null
    network: string | null
    isConnected: boolean
}

export class StacksWalletAdapter {
    private network: StacksNetwork

    constructor(networkType: 'testnet' | 'mainnet' = 'testnet') {
        this.network = networkType === 'mainnet' ? new StacksMainnet() : new StacksTestnet()
    }

    async connect(): Promise<StacksWalletState> {
        return new Promise((resolve, reject) => {
            showConnect({
                appDetails: {
                    name: 'ChainVote',
                    icon: typeof window !== 'undefined' ? window.location.origin + '/logo.png' : ''
                },
                redirectTo: '/',
                onFinish: () => {
                    resolve(this.getState())
                },
                onCancel: () => {
                    reject(new Error('User cancelled connection'))
                },
                userSession
            })
        })
    }

    disconnect(): void {
        userSession.signUserOut()
    }

    getState(): StacksWalletState {
        if (!userSession.isUserSignedIn()) {
            return {
                address: null,
                network: null,
                isConnected: false
            }
        }

        const userData = userSession.loadUserData()
        return {
            address: userData.profile.stxAddress.testnet || userData.profile.stxAddress.mainnet,
            network: this.network instanceof StacksTestnet ? 'testnet' : 'mainnet',
            isConnected: true
        }
    }

    getNetwork(): StacksNetwork {
        return this.network
    }

    getAddress(): string | null {
        if (!userSession.isUserSignedIn()) {
            return null
        }
        const userData = userSession.loadUserData()
        return userData.profile.stxAddress.testnet || userData.profile.stxAddress.mainnet
    }
}

export const stacksWallet = new StacksWalletAdapter(
    (process.env.NEXT_PUBLIC_STACKS_NETWORK as 'testnet' | 'mainnet') || 'testnet'
)

// Contract interaction helpers
export interface VotingContractConfig {
    contractAddress: string
    contractName: string
}

export class StacksVotingContract {
    private config: VotingContractConfig
    private network: StacksNetwork

    constructor(config: VotingContractConfig, network?: StacksNetwork) {
        this.config = config
        this.network = network || stacksWallet.getNetwork()
    }

    async createProposal(
        title: string,
        description: string,
        options: string[],
        duration: number
    ): Promise<string> {
        const address = stacksWallet.getAddress()
        if (!address) {
            throw new Error('Wallet not connected')
        }

        const optionsCVs = options.map(opt => stringUtf8CV(opt))

        const txOptions = {
            contractAddress: this.config.contractAddress,
            contractName: this.config.contractName,
            functionName: 'create-proposal',
            functionArgs: [
                stringAsciiCV(title),
                stringUtf8CV(description),
                listCV(optionsCVs),
                uintCV(duration)
            ],
            senderKey: address,
            validateWithAbi: true,
            network: this.network,
            anchorMode: AnchorMode.Any,
            postConditionMode: PostConditionMode.Allow
        }

        return new Promise((resolve, reject) => {
            showConnect({
                appDetails: {
                    name: 'ChainVote',
                    icon: typeof window !== 'undefined' ? window.location.origin + '/logo.png' : ''
                },
                onFinish: async (data) => {
                    try {
                        const transaction = await makeContractCall(txOptions)
                        const broadcastResponse = await broadcastTransaction(transaction, this.network)
                        resolve(broadcastResponse.txid)
                    } catch (error) {
                        reject(error)
                    }
                },
                onCancel: () => {
                    reject(new Error('Transaction cancelled'))
                },
                userSession
            })
        })
    }

    async castVote(proposalId: number, optionIndex: number): Promise<string> {
        const address = stacksWallet.getAddress()
        if (!address) {
            throw new Error('Wallet not connected')
        }

        const txOptions = {
            contractAddress: this.config.contractAddress,
            contractName: this.config.contractName,
            functionName: 'cast-vote',
            functionArgs: [uintCV(proposalId), uintCV(optionIndex)],
            senderKey: address,
            validateWithAbi: true,
            network: this.network,
            anchorMode: AnchorMode.Any,
            postConditionMode: PostConditionMode.Allow
        }

        return new Promise((resolve, reject) => {
            showConnect({
                appDetails: {
                    name: 'ChainVote',
                    icon: typeof window !== 'undefined' ? window.location.origin + '/logo.png' : ''
                },
                onFinish: async (data) => {
                    try {
                        const transaction = await makeContractCall(txOptions)
                        const broadcastResponse = await broadcastTransaction(transaction, this.network)
                        resolve(broadcastResponse.txid)
                    } catch (error) {
                        reject(error)
                    }
                },
                onCancel: () => {
                    reject(new Error('Transaction cancelled'))
                },
                userSession
            })
        })
    }

    async getProposal(proposalId: number): Promise<any> {
        const result = await callReadOnlyFunction({
            contractAddress: this.config.contractAddress,
            contractName: this.config.contractName,
            functionName: 'get-proposal',
            functionArgs: [uintCV(proposalId)],
            network: this.network,
            senderAddress: this.config.contractAddress
        })

        return cvToJSON(result)
    }

    async getVoteCount(proposalId: number, optionIndex: number): Promise<number> {
        const result = await callReadOnlyFunction({
            contractAddress: this.config.contractAddress,
            contractName: this.config.contractName,
            functionName: 'get-vote-count',
            functionArgs: [uintCV(proposalId), uintCV(optionIndex)],
            network: this.network,
            senderAddress: this.config.contractAddress
        })

        const json = cvToJSON(result)
        return json.value ? parseInt(json.value) : 0
    }

    async getUserVote(proposalId: number, voter: string): Promise<number | null> {
        const result = await callReadOnlyFunction({
            contractAddress: this.config.contractAddress,
            contractName: this.config.contractName,
            functionName: 'get-user-vote',
            functionArgs: [uintCV(proposalId), principalCV(voter)],
            network: this.network,
            senderAddress: this.config.contractAddress
        })

        const json = cvToJSON(result)
        return json.value ? parseInt(json.value) : null
    }

    async hasVoted(proposalId: number, voter: string): Promise<boolean> {
        const result = await callReadOnlyFunction({
            contractAddress: this.config.contractAddress,
            contractName: this.config.contractName,
            functionName: 'has-voted',
            functionArgs: [uintCV(proposalId), principalCV(voter)],
            network: this.network,
            senderAddress: this.config.contractAddress
        })

        const json = cvToJSON(result)
        return json.value === true
    }

    async getProposalCount(): Promise<number> {
        const result = await callReadOnlyFunction({
            contractAddress: this.config.contractAddress,
            contractName: this.config.contractName,
            functionName: 'get-proposal-count',
            functionArgs: [],
            network: this.network,
            senderAddress: this.config.contractAddress
        })

        const json = cvToJSON(result)
        return json.value ? parseInt(json.value) : 0
    }
}
