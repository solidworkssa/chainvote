// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Voting.sol";

contract VotingTest is Test {
    Voting public voting;
    address public user1 = address(0x1);
    address public user2 = address(0x2);

    function setUp() public {
        voting = new Voting();
    }

    function testCreateProposal() public {
        string[] memory options = new string[](2);
        options[0] = "Yes";
        options[1] = "No";

        uint256 proposalId = voting.createProposal(
            "Test Proposal",
            "Description",
            options,
            86400
        );

        assertEq(proposalId, 0);
        assertEq(voting.proposalCount(), 1);
    }

    function testVote() public {
        string[] memory options = new string[](2);
        options[0] = "Yes";
        options[1] = "No";

        uint256 proposalId = voting.createProposal(
            "Test Proposal",
            "Description",
            options,
            86400
        );

        vm.prank(user1);
        voting.vote(proposalId, 0);

        assertEq(voting.getVoteCount(proposalId, 0), 1);
        assertTrue(voting.getUserVote(proposalId, user1));
    }

    function testCannotVoteTwice() public {
        string[] memory options = new string[](2);
        options[0] = "Yes";
        options[1] = "No";

        uint256 proposalId = voting.createProposal(
            "Test Proposal",
            "Description",
            options,
            86400
        );

        vm.startPrank(user1);
        voting.vote(proposalId, 0);
        
        vm.expectRevert(Voting.AlreadyVoted.selector);
        voting.vote(proposalId, 1);
        vm.stopPrank();
    }
}
