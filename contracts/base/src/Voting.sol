// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Voting {
    struct Proposal {
        uint256 id;
        address creator;
        string title;
        string description;
        uint256 endTime;
        string[] options;
        bool active;
        uint256 totalVotes;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(uint256 => mapping(uint256 => uint256)) public voteCounts;
    
    uint256 public proposalCount;

    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed creator,
        string title,
        uint256 endTime
    );
    
    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        uint256 optionIndex
    );

    error ProposalNotActive();
    error AlreadyVoted();
    error InvalidOption();
    error ProposalEnded();
    error EmptyTitle();
    error EmptyOptions();
    error InvalidDuration();

    function createProposal(
        string memory _title,
        string memory _description,
        string[] memory _options,
        uint256 _duration
    ) external returns (uint256) {
        if (bytes(_title).length == 0) revert EmptyTitle();
        if (_options.length == 0) revert EmptyOptions();
        if (_duration == 0) revert InvalidDuration();

        uint256 proposalId = proposalCount++;
        uint256 endTime = block.timestamp + _duration;

        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.creator = msg.sender;
        proposal.title = _title;
        proposal.description = _description;
        proposal.endTime = endTime;
        proposal.options = _options;
        proposal.active = true;
        proposal.totalVotes = 0;

        emit ProposalCreated(proposalId, msg.sender, _title, endTime);

        return proposalId;
    }

    function vote(uint256 _proposalId, uint256 _optionIndex) external {
        Proposal storage proposal = proposals[_proposalId];
        
        if (!proposal.active) revert ProposalNotActive();
        if (block.timestamp >= proposal.endTime) revert ProposalEnded();
        if (hasVoted[_proposalId][msg.sender]) revert AlreadyVoted();
        if (_optionIndex >= proposal.options.length) revert InvalidOption();

        hasVoted[_proposalId][msg.sender] = true;
        voteCounts[_proposalId][_optionIndex]++;
        proposal.totalVotes++;

        emit VoteCast(_proposalId, msg.sender, _optionIndex);
    }

    function getProposal(uint256 _proposalId) external view returns (
        uint256 id,
        address creator,
        string memory title,
        string memory description,
        uint256 endTime,
        string[] memory options,
        bool active,
        uint256 totalVotes
    ) {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.creator,
            proposal.title,
            proposal.description,
            proposal.endTime,
            proposal.options,
            proposal.active,
            proposal.totalVotes
        );
    }

    function getVoteCount(uint256 _proposalId, uint256 _optionIndex) external view returns (uint256) {
        return voteCounts[_proposalId][_optionIndex];
    }

    function getUserVote(uint256 _proposalId, address _voter) external view returns (bool) {
        return hasVoted[_proposalId][_voter];
    }

    function endProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(msg.sender == proposal.creator, "Only creator can end proposal");
        require(proposal.active, "Proposal already ended");
        
        proposal.active = false;
    }
}
