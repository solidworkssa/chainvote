// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ChainVote.sol";

contract ChainVoteTest is Test {
    ChainVote public chainVote;
    address public owner;
    address public user1;
    address public user2;
    address public user3;

    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed creator,
        string title,
        uint256 startTime,
        uint256 endTime,
        ChainVote.VotingMechanism mechanism
    );

    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        uint256 optionIndex,
        uint256 weight
    );

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        chainVote = new ChainVote();
    }

    function testCreateProposal() public {
        string memory title = "Test Proposal";
        string memory description = "This is a test proposal";
        string[] memory options = new string[](3);
        options[0] = "Option A";
        options[1] = "Option B";
        options[2] = "Option C";
        uint256 duration = 7 days;

        vm.expectEmit(true, true, false, true);
        emit ProposalCreated(
            0,
            address(this),
            title,
            block.timestamp,
            block.timestamp + duration,
            ChainVote.VotingMechanism.Simple
        );

        uint256 proposalId = chainVote.createProposal(
            title,
            description,
            options,
            duration,
            ChainVote.VotingMechanism.Simple,
            0
        );

        assertEq(proposalId, 0);
        assertEq(chainVote.proposalCount(), 1);
    }

    function testCannotCreateProposalWithEmptyTitle() public {
        string memory title = "";
        string memory description = "Description";
        string[] memory options = new string[](2);
        options[0] = "Yes";
        options[1] = "No";

        vm.expectRevert(ChainVote.EmptyTitle.selector);
        chainVote.createProposal(
            title,
            description,
            options,
            1 days,
            ChainVote.VotingMechanism.Simple,
            0
        );
    }

    function testCannotCreateProposalWithNoOptions() public {
        string memory title = "Title";
        string memory description = "Description";
        string[] memory options = new string[](0);

        vm.expectRevert(ChainVote.EmptyOptions.selector);
        chainVote.createProposal(
            title,
            description,
            options,
            1 days,
            ChainVote.VotingMechanism.Simple,
            0
        );
    }

    function testCannotCreateProposalWithInvalidDuration() public {
        string memory title = "Title";
        string memory description = "Description";
        string[] memory options = new string[](2);
        options[0] = "Yes";
        options[1] = "No";

        // Too short
        vm.expectRevert(ChainVote.InvalidDuration.selector);
        chainVote.createProposal(
            title,
            description,
            options,
            30 minutes,
            ChainVote.VotingMechanism.Simple,
            0
        );

        // Too long
        vm.expectRevert(ChainVote.InvalidDuration.selector);
        chainVote.createProposal(
            title,
            description,
            options,
            31 days,
            ChainVote.VotingMechanism.Simple,
            0
        );
    }

    function testVote() public {
        uint256 proposalId = _createTestProposal();

        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit VoteCast(proposalId, user1, 0, 1);
        chainVote.vote(proposalId, 0);

        (bool hasVoted, uint256 optionIndex, uint256 weight, ) = chainVote.getUserVote(proposalId, user1);
        assertTrue(hasVoted);
        assertEq(optionIndex, 0);
        assertEq(weight, 1);

        uint256 voteCount = chainVote.getVoteCount(proposalId, 0);
        assertEq(voteCount, 1);
    }

    function testCannotVoteTwice() public {
        uint256 proposalId = _createTestProposal();

        vm.startPrank(user1);
        chainVote.vote(proposalId, 0);

        vm.expectRevert(ChainVote.AlreadyVoted.selector);
        chainVote.vote(proposalId, 1);
        vm.stopPrank();
    }

    function testCannotVoteOnInvalidOption() public {
        uint256 proposalId = _createTestProposal();

        vm.prank(user1);
        vm.expectRevert(ChainVote.InvalidOption.selector);
        chainVote.vote(proposalId, 10); // Only 3 options exist
    }

    function testCannotVoteAfterProposalEnds() public {
        uint256 proposalId = _createTestProposal();

        // Fast forward past end time
        vm.warp(block.timestamp + 8 days);

        vm.prank(user1);
        vm.expectRevert(ChainVote.ProposalEnded.selector);
        chainVote.vote(proposalId, 0);
    }

    function testDelegateVote() public {
        uint256 proposalId = _createTestProposal();

        vm.prank(user1);
        chainVote.delegateVote(proposalId, user2);

        // User1 should not be able to vote after delegating
        vm.prank(user1);
        vm.expectRevert(ChainVote.Unauthorized.selector);
        chainVote.vote(proposalId, 0);
    }

    function testCannotDelegateToSelf() public {
        uint256 proposalId = _createTestProposal();

        vm.prank(user1);
        vm.expectRevert(ChainVote.Unauthorized.selector);
        chainVote.delegateVote(proposalId, user1);
    }

    function testEndProposal() public {
        uint256 proposalId = _createTestProposal();

        // Vote
        vm.prank(user1);
        chainVote.vote(proposalId, 0);

        // Fast forward past end time
        vm.warp(block.timestamp + 8 days);

        chainVote.endProposal(proposalId);

        (, , , , , , ChainVote.ProposalStatus status, , , , ) = chainVote.getProposal(proposalId);
        assertEq(uint(status), uint(ChainVote.ProposalStatus.Ended));
    }

    function testCannotEndActiveProposal() public {
        uint256 proposalId = _createTestProposal();

        vm.expectRevert(ChainVote.ProposalNotActive.selector);
        chainVote.endProposal(proposalId);
    }

    function testCancelProposal() public {
        uint256 proposalId = _createTestProposal();

        chainVote.cancelProposal(proposalId);

        (, , , , , , ChainVote.ProposalStatus status, , , , ) = chainVote.getProposal(proposalId);
        assertEq(uint(status), uint(ChainVote.ProposalStatus.Cancelled));
    }

    function testOnlyCreatorOrOwnerCanCancel() public {
        uint256 proposalId = _createTestProposal();

        vm.prank(user1);
        vm.expectRevert(ChainVote.Unauthorized.selector);
        chainVote.cancelProposal(proposalId);
    }

    function testQuorumTracking() public {
        string memory title = "Quorum Test";
        string memory description = "Testing quorum";
        string[] memory options = new string[](2);
        options[0] = "Yes";
        options[1] = "No";

        uint256 proposalId = chainVote.createProposal(
            title,
            description,
            options,
            7 days,
            ChainVote.VotingMechanism.Simple,
            3 // Quorum of 3 votes
        );

        (, , , , , , , , , , bool quorumReached) = chainVote.getProposal(proposalId);
        assertFalse(quorumReached);

        // Cast 3 votes
        vm.prank(user1);
        chainVote.vote(proposalId, 0);

        vm.prank(user2);
        chainVote.vote(proposalId, 0);

        vm.prank(user3);
        chainVote.vote(proposalId, 1);

        (, , , , , , , , , , quorumReached) = chainVote.getProposal(proposalId);
        assertTrue(quorumReached);
    }

    function testGetWinningOption() public {
        uint256 proposalId = _createTestProposal();

        // Vote: 2 for option 0, 1 for option 1
        vm.prank(user1);
        chainVote.vote(proposalId, 0);

        vm.prank(user2);
        chainVote.vote(proposalId, 0);

        vm.prank(user3);
        chainVote.vote(proposalId, 1);

        uint256 winningOption = chainVote.getWinningOption(proposalId);
        assertEq(winningOption, 0);
    }

    function testPauseUnpause() public {
        chainVote.pause();

        string[] memory options = new string[](2);
        options[0] = "Yes";
        options[1] = "No";

        vm.expectRevert();
        chainVote.createProposal(
            "Title",
            "Description",
            options,
            1 days,
            ChainVote.VotingMechanism.Simple,
            0
        );

        chainVote.unpause();

        // Should work now
        chainVote.createProposal(
            "Title",
            "Description",
            options,
            1 days,
            ChainVote.VotingMechanism.Simple,
            0
        );
    }

    function testOnlyOwnerCanPause() public {
        vm.prank(user1);
        vm.expectRevert();
        chainVote.pause();
    }

    // Helper function
    function _createTestProposal() internal returns (uint256) {
        string memory title = "Test Proposal";
        string memory description = "This is a test";
        string[] memory options = new string[](3);
        options[0] = "Option A";
        options[1] = "Option B";
        options[2] = "Option C";

        return chainVote.createProposal(
            title,
            description,
            options,
            7 days,
            ChainVote.VotingMechanism.Simple,
            0
        );
    }

    function testFuzz_Vote(address voter, uint8 optionIndex) public {
        vm.assume(voter != address(0));
        vm.assume(optionIndex < 3);

        uint256 proposalId = _createTestProposal();

        vm.prank(voter);
        chainVote.vote(proposalId, optionIndex);

        (bool hasVoted, uint256 votedOption, , ) = chainVote.getUserVote(proposalId, voter);
        assertTrue(hasVoted);
        assertEq(votedOption, optionIndex);
    }
}
