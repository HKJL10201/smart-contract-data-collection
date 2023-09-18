// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


import "./ERC20MintableBurnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title JeDAO contract with voting and ERC20 compatibility
/// @author Omur Kubanychbekov
/// @notice You can use this contract for make DAO and votings
/// @dev All functions tested successfully and have no errors

contract JeDAO is ReentrancyGuard {
    address public chairman;
    uint256 private _minQuorum;
    uint256 private _debatePeriod;
    uint256 private _proposalID;
    ERC20MintableBurnable private _voteToken;

    struct Proposal {
        uint256 finishTime; 
        uint256 votesFor;
        uint256 votesAgainst;
        address recipient;
        bytes callData;
        string description;
    }

    struct Voter {
        uint256 deposit;
        uint256 withdrawTime;
        mapping(uint256 => uint256) votedAmount;
    }
    
    mapping(uint256 => Proposal) private _proposals;
    mapping(address => Voter) private _voters;

    /// @notice Deploys the contract with the initial parameters
    /// (chairman, voteToken, minimumQuorum, debatingPeriodDuration)
    /// @dev Constructor should be used when deploying contract,
    /// @param chairPerson address of the chairman
    /// @param voteToken address of the token used for voting
    /// @param minimumQuorum minimum quorum needed for successful voting
    /// @param debatingPeriodDuration debating period 
    constructor(
        address chairPerson,
        address voteToken,
        uint256 minimumQuorum,
        uint256 debatingPeriodDuration
    ) {
        chairman = chairPerson;
        _voteToken = ERC20MintableBurnable(voteToken);
        _minQuorum = minimumQuorum;
        _debatePeriod = debatingPeriodDuration;
    }


    /// @dev Modifier for addProposal function
    modifier onlyChairman {
       require(msg.sender == chairman, "Chairman only");
       _;
    }

    /// @notice Event that notices about added new proposal
    event NewProposal(uint256 indexed id, address recipient, string description);
    
    /// @notice Event that notices about finished proposal
    event FinishedProposal(uint256 indexed id, bool indexed called, uint256 forVotes, uint256 againstVotes);


    /// @notice Function that adds new proposal
    /// @param callData of the function that will be called
    /// should be encoded as bytes
    /// @param _recipient address of the contract that will call the function
    /// @return count of total proposals
    function addProposal(
        bytes memory callData,
        address _recipient,
        string memory description
    ) external onlyChairman returns(uint256) {
        Proposal storage newProposal = _proposals[_proposalID];

        emit NewProposal(_proposalID, _recipient, description);

        _proposalID++;

        newProposal.finishTime = block.timestamp + _debatePeriod;
        newProposal.recipient = _recipient;
        newProposal.callData = callData;
        newProposal.description = description;

        return _proposalID;
    }


    /// @notice can be called by anyone who has enough tokens deposited
    /// @notice voting is active until finish function is called
    /// @notice voter can add tokens to his existing deposit
    /// and vote for proposal he voted already with newly added tokens
    /// @param isVoteFor true if vote for, false if vote against
    /// @return true if voting is successful
    function vote(
        uint256 proposalID,
        uint256 amount,
        bool isVoteFor
    ) external returns(bool) {
        Proposal storage proposal = _proposals[proposalID];
        Voter storage voter = _voters[msg.sender];

        require(proposal.finishTime > 0, "Proposal is not active");
        require(voter.deposit - voter.votedAmount[proposalID] >= amount, "Not enough tokens");

        if(isVoteFor) {
            proposal.votesFor += amount;
            voter.votedAmount[proposalID] += amount;
        } else {
            proposal.votesAgainst += amount;
            voter.votedAmount[proposalID] += amount;
        }

        if(voter.withdrawTime < proposal.finishTime) {
            voter.withdrawTime = proposal.finishTime;
        }

        return true;
    }


    /// @notice can be called by anyone to finish proposal
    /// @notice calls the function if quorum is reached and
    /// votes for is greater than votes against
    /// otherwise proposal finishes with no call
    /// @return true if proposal is finished successfully
    function finishProposal(uint256 proposalID) external returns(bool) {
        Proposal storage proposal = _proposals[proposalID];
        require(block.timestamp >= proposal.finishTime, "Proposal is not finished");
        require(proposal.votesFor + proposal.votesAgainst >= _minQuorum, "Not enough votes");

        bool isCalling = proposal.votesFor > proposal.votesAgainst;

        if(isCalling) {
            (bool success, ) = proposal.recipient.call{value: 0}
                (proposal.callData);

             require(success, "Operation failed");
        }

        emit FinishedProposal(proposalID, isCalling, proposal.votesFor, proposal.votesAgainst);

        proposal.finishTime = 0;

        return true;
    }


    /// @notice can be called by anyone to deposit tokens
    /// @return true if deposit is successful
    function deposit(uint256 amount) external returns(bool) {
        _voteToken.transferFrom(msg.sender, address(this), amount);
        _voters[msg.sender].deposit += amount;

        return true;
    }
    

    /// @notice can be called by anyone to withdraw deposited tokens
    /// @return true if withdraw is successful
    function withdraw(uint256 amount) external nonReentrant returns(bool) {
        Voter storage voter = _voters[msg.sender];

        require(block.timestamp >= voter.withdrawTime, "Can't withdraw yet");
        require(voter.deposit >= amount, "Not enough tokens");

        _voteToken.transfer(msg.sender, amount);
        voter.deposit -= amount;

        return true;
    }
}