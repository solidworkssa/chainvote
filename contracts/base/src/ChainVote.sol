// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title ChainVote - Decentralized Voting System
/// @author Multi-Chain dApp Team
/// @notice This contract allows users to create and vote on proposals with various voting mechanisms
/// @dev Implements weighted voting, delegation, and quadratic voting options
contract ChainVote is Ownable, ReentrancyGuard, Pausable {
    /// @notice Voting mechanism types
    enum VotingMechanism {
        Simple,        // One address = one vote
        Weighted,      // Vote weight based on token balance
        Quadratic      // Quadratic voting (cost increases quadratically)
    }

    /// @notice Proposal status
    enum ProposalStatus {
        Active,
        Ended,
        Cancelled,
        Executed
    }

    /// @notice Proposal structure
    struct Proposal {
        uint256 id;
        address creator;
        string title;
        string description;
        uint256 startTime;
        uint256 endTime;
        string[] options;
        ProposalStatus status;
        uint256 totalVotes;
        VotingMechanism mechanism;
        uint256 quorum;              // Minimum votes required
        bool quorumReached;
        mapping(uint256 => uint256) voteCounts;
        mapping(address => Vote) votes;
    }

    /// @notice Vote structure
    struct Vote {
        bool hasVoted;
        uint256 optionIndex;
        uint256 weight;
        uint256 timestamp;
    }

    /// @notice Delegation structure
    struct Delegation {
        address delegate;
        uint256 timestamp;
    }

    /// @dev Proposal storage
    mapping(uint256 => Proposal) private proposals;
    
    /// @dev Delegation tracking
    mapping(address => mapping(uint256 => Delegation)) public delegations;
    
    /// @dev Proposal counter
    uint256 public proposalCount;
    
    /// @dev Minimum proposal duration (1 hour)
    uint256 public constant MIN_DURATION = 1 hours;
    
    /// @dev Maximum proposal duration (30 days)
    uint256 public constant MAX_DURATION = 30 days;
    
    /// @dev Maximum options per proposal
    uint256 public constant MAX_OPTIONS = 20;

    /// @notice Emitted when a new proposal is created
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed creator,
        string title,
        uint256 startTime,
        uint256 endTime,
        VotingMechanism mechanism
    );
    
    /// @notice Emitted when a vote is cast
    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        uint256 optionIndex,
        uint256 weight
    );

    /// @notice Emitted when a proposal is cancelled
    event ProposalCancelled(uint256 indexed proposalId, address indexed canceller);

    /// @notice Emitted when a proposal ends
    event ProposalEnded(uint256 indexed proposalId, uint256 winningOption);

    /// @notice Emitted when voting is delegated
    event VoteDelegated(
        uint256 indexed proposalId,
        address indexed delegator,
        address indexed delegate
    );

    /// @dev Custom errors
    error ProposalNotActive();
    error AlreadyVoted();
    error InvalidOption();
    error ProposalEnded();
    error EmptyTitle();
    error EmptyOptions();
    error InvalidDuration();
    error TooManyOptions();
    error Unauthorized();
    error ProposalNotFound();
    error InvalidQuorum();
    error QuorumNotReached();

    constructor() Ownable(msg.sender) {}

    /// @notice Create a new proposal
    /// @param _title Proposal title
    /// @param _description Proposal description
    /// @param _options Array of voting options
    /// @param _duration Duration in seconds
    /// @param _mechanism Voting mechanism to use
    /// @param _quorum Minimum votes required (0 for no quorum)
    /// @return proposalId The ID of the created proposal
    function createProposal(
        string memory _title,
        string memory _description,
        string[] memory _options,
        uint256 _duration,
        VotingMechanism _mechanism,
        uint256 _quorum
    ) external whenNotPaused nonReentrant returns (uint256) {
        if (bytes(_title).length == 0) revert EmptyTitle();
        if (_options.length == 0) revert EmptyOptions();
        if (_options.length > MAX_OPTIONS) revert TooManyOptions();
        if (_duration < MIN_DURATION || _duration > MAX_DURATION) revert InvalidDuration();

        uint256 proposalId = proposalCount++;
        Proposal storage proposal = proposals[proposalId];
        
        proposal.id = proposalId;
        proposal.creator = msg.sender;
        proposal.title = _title;
        proposal.description = _description;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + _duration;
        proposal.options = _options;
        proposal.status = ProposalStatus.Active;
        proposal.totalVotes = 0;
        proposal.mechanism = _mechanism;
        proposal.quorum = _quorum;
        proposal.quorumReached = false;

        emit ProposalCreated(
            proposalId,
            msg.sender,
            _title,
            proposal.startTime,
            proposal.endTime,
            _mechanism
        );

        return proposalId;
    }

    /// @notice Cast a vote on a proposal
    /// @param _proposalId The proposal ID
    /// @param _optionIndex The option to vote for
    function vote(uint256 _proposalId, uint256 _optionIndex) 
        external 
        whenNotPaused 
        nonReentrant 
    {
        Proposal storage proposal = proposals[_proposalId];
        
        if (proposal.status != ProposalStatus.Active) revert ProposalNotActive();
        if (block.timestamp >= proposal.endTime) revert ProposalEnded();
        if (proposal.votes[msg.sender].hasVoted) revert AlreadyVoted();
        if (_optionIndex >= proposal.options.length) revert InvalidOption();

        // Check for delegation
        Delegation memory delegation = delegations[msg.sender][_proposalId];
        if (delegation.delegate != address(0)) {
            revert Unauthorized(); // Cannot vote if delegated
        }

        uint256 voteWeight = _calculateVoteWeight(msg.sender, proposal.mechanism);

        proposal.votes[msg.sender] = Vote({
            hasVoted: true,
            optionIndex: _optionIndex,
            weight: voteWeight,
            timestamp: block.timestamp
        });

        proposal.voteCounts[_optionIndex] += voteWeight;
        proposal.totalVotes += voteWeight;

        // Check quorum
        if (proposal.quorum > 0 && proposal.totalVotes >= proposal.quorum) {
            proposal.quorumReached = true;
        }

        emit VoteCast(_proposalId, msg.sender, _optionIndex, voteWeight);
    }

    /// @notice Delegate voting power to another address
    /// @param _proposalId The proposal ID
    /// @param _delegate The address to delegate to
    function delegateVote(uint256 _proposalId, address _delegate) 
        external 
        whenNotPaused 
    {
        Proposal storage proposal = proposals[_proposalId];
        
        if (proposal.status != ProposalStatus.Active) revert ProposalNotActive();
        if (block.timestamp >= proposal.endTime) revert ProposalEnded();
        if (proposal.votes[msg.sender].hasVoted) revert AlreadyVoted();
        if (_delegate == address(0) || _delegate == msg.sender) revert Unauthorized();

        delegations[msg.sender][_proposalId] = Delegation({
            delegate: _delegate,
            timestamp: block.timestamp
        });

        emit VoteDelegated(_proposalId, msg.sender, _delegate);
    }

    /// @notice End a proposal (can be called by anyone after end time)
    /// @param _proposalId The proposal ID
    function endProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        
        if (proposal.status != ProposalStatus.Active) revert ProposalNotActive();
        if (block.timestamp < proposal.endTime) revert ProposalNotActive();

        proposal.status = ProposalStatus.Ended;

        uint256 winningOption = _getWinningOption(_proposalId);
        emit ProposalEnded(_proposalId, winningOption);
    }

    /// @notice Cancel a proposal (only creator or owner)
    /// @param _proposalId The proposal ID
    function cancelProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        
        if (msg.sender != proposal.creator && msg.sender != owner()) {
            revert Unauthorized();
        }
        if (proposal.status != ProposalStatus.Active) revert ProposalNotActive();

        proposal.status = ProposalStatus.Cancelled;
        emit ProposalCancelled(_proposalId, msg.sender);
    }

    /// @notice Get proposal details
    /// @param _proposalId The proposal ID
    /// @return Proposal details
    function getProposal(uint256 _proposalId) 
        external 
        view 
        returns (
            uint256 id,
            address creator,
            string memory title,
            string memory description,
            uint256 startTime,
            uint256 endTime,
            string[] memory options,
            ProposalStatus status,
            uint256 totalVotes,
            VotingMechanism mechanism,
            uint256 quorum,
            bool quorumReached
        ) 
    {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.creator,
            proposal.title,
            proposal.description,
            proposal.startTime,
            proposal.endTime,
            proposal.options,
            proposal.status,
            proposal.totalVotes,
            proposal.mechanism,
            proposal.quorum,
            proposal.quorumReached
        );
    }

    /// @notice Get vote count for a specific option
    /// @param _proposalId The proposal ID
    /// @param _optionIndex The option index
    /// @return The vote count
    function getVoteCount(uint256 _proposalId, uint256 _optionIndex) 
        external 
        view 
        returns (uint256) 
    {
        return proposals[_proposalId].voteCounts[_optionIndex];
    }

    /// @notice Get user's vote for a proposal
    /// @param _proposalId The proposal ID
    /// @param _voter The voter address
    /// @return Vote details
    function getUserVote(uint256 _proposalId, address _voter) 
        external 
        view 
        returns (
            bool hasVoted,
            uint256 optionIndex,
            uint256 weight,
            uint256 timestamp
        ) 
    {
        Vote storage userVote = proposals[_proposalId].votes[_voter];
        return (
            userVote.hasVoted,
            userVote.optionIndex,
            userVote.weight,
            userVote.timestamp
        );
    }

    /// @notice Get the winning option for a proposal
    /// @param _proposalId The proposal ID
    /// @return The winning option index
    function getWinningOption(uint256 _proposalId) 
        external 
        view 
        returns (uint256) 
    {
        return _getWinningOption(_proposalId);
    }

    /// @notice Pause the contract (owner only)
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause the contract (owner only)
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Calculate vote weight based on mechanism
    function _calculateVoteWeight(address _voter, VotingMechanism _mechanism) 
        private 
        view 
        returns (uint256) 
    {
        if (_mechanism == VotingMechanism.Simple) {
            return 1;
        } else if (_mechanism == VotingMechanism.Weighted) {
            // In a real implementation, this would check token balance
            // For now, return 1
            return 1;
        } else {
            // Quadratic voting - would need additional logic
            return 1;
        }
    }

    /// @dev Get the winning option
    function _getWinningOption(uint256 _proposalId) 
        private 
        view 
        returns (uint256) 
    {
        Proposal storage proposal = proposals[_proposalId];
        uint256 winningVotes = 0;
        uint256 winningOption = 0;

        for (uint256 i = 0; i < proposal.options.length; i++) {
            if (proposal.voteCounts[i] > winningVotes) {
                winningVotes = proposal.voteCounts[i];
                winningOption = i;
            }
        }

        return winningOption;
    }
}
