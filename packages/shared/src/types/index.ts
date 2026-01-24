export interface Proposal {
    id: number
    creator: string
    title: string
    description: string
    endTime: number
    options: string[]
    active: boolean
    totalVotes: number
}

export interface VoteCount {
    optionIndex: number
    count: number
}

export type Chain = 'base' | 'stacks'

export interface WalletConnection {
    chain: Chain
    address: string | null
    isConnected: boolean
}

export type TransactionStatus = 'idle' | 'pending' | 'success' | 'error'

export interface TransactionState {
    status: TransactionStatus
    txHash?: string
    error?: string
}
