// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract ETHVoteBallot {


    address owner;                  
    bool    optionsFinalized;    
    string  ballotName;             
    uint    registeredVoterCount;  
    uint    ballotEndTime;          

    
    modifier onlyOwner
    {
        if( msg.sender != owner )
            revert();
        _;
    }

    
    constructor(string memory _ballotName, uint _ballotEndTime)
    {
        if( block.timestamp > _ballotEndTime)
            revert();

        owner                   = msg.sender;       
        optionsFinalized        = false;            
        ballotName              = _ballotName;      
        registeredVoterCount    = 0;                
        ballotEndTime           = _ballotEndTime;   
    }

    struct VotingOption
    {
        string name;    
        uint voteCount; 
    }
    VotingOption[] public votingOptions; 

   
    function addVotingOption(string memory _votingOptionName) external onlyOwner
    {
        if( block.timestamp > ballotEndTime) revert();

        if(optionsFinalized == true)    
            revert();

        votingOptions.push(VotingOption({
            name: _votingOptionName,
            voteCount: 0
        }));
    }

    
    function finalizeVotingOptions() external onlyOwner
    {
        if(block.timestamp > ballotEndTime) revert();

        if(votingOptions.length < 2) revert();

        optionsFinalized = true;    
    }

    
    struct Voter
    {
        bool eligableToVote;    
        bool voted;             
        uint votedFor;          
    }
    mapping(address => Voter) public voters; 

    
    function giveRightToVote(address _voter) external onlyOwner
    {
        if(block.timestamp > ballotEndTime) revert();
        voters[_voter].eligableToVote = true;

        registeredVoterCount += 1;      
    }

    
    function vote(uint _votingOptionIndex) external
    {
        if(block.timestamp > ballotEndTime) revert();

        if(optionsFinalized == false)        
            revert();

        Voter memory voter = voters[msg.sender];      

        if(voter.eligableToVote == false)
            revert();

        if(voter.voted == true) 
            votingOptions[voter.votedFor].voteCount -= 1;

        voter.voted = true;
        voter.votedFor = _votingOptionIndex;

        votingOptions[_votingOptionIndex].voteCount += 1;

    }

    

    
    function getBallotName() external view returns (string memory _ballotName)
    {
         _ballotName = ballotName;
    }

   
    function getVotingOptionsLength() external view returns (uint _votingOptionsLength)
    {
        _votingOptionsLength = votingOptions.length;
    }

    
    function getRegisteredVoterCount() external view returns (uint _registeredVoterCount)
    {
        _registeredVoterCount = registeredVoterCount;
    }

    
    function getVotingOptionsName(uint _index) external view returns (string memory _votingOptionsName)
    {
        _votingOptionsName = votingOptions[_index].name;
    }

    
    function getVotingOptionsVoteCount(uint _index) external view returns (uint _votingOptionsVoteCount)
    {
        _votingOptionsVoteCount = votingOptions[_index].voteCount;
    }

    
    function getOptionsFinalized() external view returns (bool _optionsFinalized)
    {
        _optionsFinalized = optionsFinalized;
    }

    
    function getBallotEndTime() external view returns (uint _ballotEndTime)
    {
        _ballotEndTime = ballotEndTime;
    }

}