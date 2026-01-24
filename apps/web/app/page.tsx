'use client'

import { useState } from 'react'
import { Button, Card } from 'shared'

export default function Home() {
    const [activeChain, setActiveChain] = useState<'base' | 'stacks'>('base')

    return (
        <main className="min-h-screen bg-white">
            <nav className="border-b-2 border-black">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="flex justify-between items-center h-16">
                        <h1 className="text-2xl font-bold">ChainVote</h1>
                        <div className="flex gap-4">
                            <Button variant="outline" size="sm">
                                Connect Wallet
                            </Button>
                        </div>
                    </div>
                </div>
            </nav>

            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                <div className="mb-8">
                    <h2 className="text-3xl font-bold mb-2">Decentralized Voting</h2>
                    <p className="text-gray-600">
                        Create and vote on proposals across Base and Stacks blockchains
                    </p>
                </div>

                <div className="flex gap-4 mb-8">
                    <Button
                        variant={activeChain === 'base' ? 'primary' : 'outline'}
                        onClick={() => setActiveChain('base')}
                    >
                        Base Network
                    </Button>
                    <Button
                        variant={activeChain === 'stacks' ? 'primary' : 'outline'}
                        onClick={() => setActiveChain('stacks')}
                    >
                        Stacks Network
                    </Button>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    <Card>
                        <h3 className="text-xl font-bold mb-2">Sample Proposal</h3>
                        <p className="text-gray-600 mb-4">
                            This is a placeholder proposal. Connect your wallet to see real proposals.
                        </p>
                        <Button size="sm">View Details</Button>
                    </Card>
                </div>
            </div>
        </main>
    )
}
