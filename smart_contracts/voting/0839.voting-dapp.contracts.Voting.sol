// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Voting
{
    // define the votes possibilities
    enum Vote { UNDEFINED, YES, NO }
    
    // events
    event CreateProposal(Proposal proposal);
    event UserVote(uint256 proposal);
    event Close(uint256 proposal);
    
    // represents a proposal
    struct Proposal
    {
        bytes32 name;
        uint256 voteCount;
        uint256 startDate;
        uint256 endDate;
        bool closed;
    }
    
    // all proposals
    Proposal[] public proposals;
    address public owner;
    
    // proposal => user => vote
    mapping(uint256 => mapping(address => Vote)) voted;
    
    // address => proposals
    mapping(address => uint256[]) userVotes;
    
    modifier proposalOpened(uint256 _proposal) 
    {
        require(proposals[_proposal].closed == false, "Proposal is closed");
        require(block.timestamp <= proposals[_proposal].endDate, "Proposal has ended");
        _;
    }
    
    modifier onlyOwner()
    {
        require(msg.sender == owner, "Not allowed to do this action");
        _;
    }
    
    constructor()
    {
        owner = msg.sender;
    }
    
    // create a new proposal, can only be called by owner
    function create(bytes32 _proposalName, uint256 _endDate) public onlyOwner
    {
        require(_proposalName != '', "Proposal must have a name");
        require(_endDate > block.timestamp, "End date must be greater than current date");
        
        Proposal memory proposal = Proposal({
            name: _proposalName,
            voteCount: 0,
            startDate: block.timestamp,
            endDate: _endDate,
            closed: false
        });
        
        proposals.push(proposal);
        emit CreateProposal(proposal);
    }
    
    // close a proposal, can only be called by owner and proposal must be opened
    function close(uint256 _proposal) public onlyOwner proposalOpened(_proposal)
    {
        require(_proposal < proposals.length, "Specified proposal doesn't exist");
        proposals[_proposal].closed = true;

        emit Close(_proposal);
    }
    
    // update a proposal, can only be called by owner
    function update(uint256 _proposal, bytes32 _proposalName) public onlyOwner
    {
        require(_proposal < proposals.length, "Specified proposal doesn't exist");
        proposals[_proposal].name = _proposalName;
    }
    
    // vote for a specific proposal
    function vote(uint256 _proposal, Vote _vote) proposalOpened(_proposal) public
    {
        require(voted[_proposal][msg.sender] == Vote.UNDEFINED, "Already voted");
        require(_vote == Vote.YES || _vote == Vote.NO, "Invalid vote");
        
        voted[_proposal][msg.sender] = _vote;
        userVotes[msg.sender].push(_proposal);
        proposals[_proposal].voteCount++;
        
        emit UserVote(_proposal);
    }
    
    // get contract information (proposals, userVotes)
    function getProposalsAndUserVotes() external view returns (Proposal[] memory, uint256[] memory)
    {
        return (proposals, userVotes[msg.sender]);
    }
    
    // get one proposal
    function getProposal(uint256 _proposal) external view returns (Proposal memory)
    {
        return proposals[_proposal];
    }
}