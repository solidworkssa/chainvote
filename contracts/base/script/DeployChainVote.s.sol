// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ChainVote.sol";

contract DeployChainVote is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy ChainVote contract
        ChainVote chainVote = new ChainVote();

        console.log("ChainVote deployed to:", address(chainVote));
        console.log("Owner:", chainVote.owner());
        console.log("Proposal Count:", chainVote.proposalCount());

        vm.stopBroadcast();

        // Verify contract on Basescan
        console.log("\nTo verify the contract, run:");
        console.log("forge verify-contract", address(chainVote), "src/ChainVote.sol:ChainVote --chain-id 8453");
    }
}
