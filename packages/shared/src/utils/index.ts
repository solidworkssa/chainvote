export const formatAddress = (address: string, chars = 4): string => {
    if (!address) return ''
    return `${address.slice(0, chars + 2)}...${address.slice(-chars)}`
}

export const formatTimestamp = (timestamp: number): string => {
    return new Date(timestamp * 1000).toLocaleString()
}

export const formatDuration = (seconds: number): string => {
    const days = Math.floor(seconds / 86400)
    const hours = Math.floor((seconds % 86400) / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)

    if (days > 0) return `${days}d ${hours}h`
    if (hours > 0) return `${hours}h ${minutes}m`
    return `${minutes}m`
}

export const getExplorerUrl = (chain: 'base' | 'stacks', txHash: string): string => {
    if (chain === 'base') {
        return `https://sepolia.basescan.org/tx/${txHash}`
    }
    return `https://explorer.hiro.so/txid/${txHash}?chain=testnet`
}

export const truncateText = (text: string, maxLength: number): string => {
    if (text.length <= maxLength) return text
    return text.slice(0, maxLength) + '...'
}
