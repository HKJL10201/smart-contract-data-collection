pragma solidity ^0.5.0;
contract Ballot {

    struct Voter {                     
        uint weight;
        bool voted;
        uint8 vote;
    }
    struct Proposal {                  
        uint voteCount;
    }

    address chairperson;
    mapping(address => Voter) voters;  
    Proposal[] proposals;
    uint public startTime;
    
    constructor(uint8 numProposals) public  {
        chairperson = msg.sender;
        voters[chairperson].weight = 2; // weight 2 for testing purposes
        proposals.length = numProposals;
    }
    
    function register(address voter) public  {
        voters[voter].weight = 1;
        voters[voter].voted = false;
    }

   
    function vote(uint8 toProposal) public  {
        Voter memory sender = voters[msg.sender];
        if (sender.voted || toProposal >= proposals.length) return; 
        sender.voted = true;
        sender.vote = toProposal;   
        proposals[toProposal].voteCount += sender.weight;
    }

    function reqWinner() public view returns (uint8 _winningProposal) {
        uint256 winningVoteCount = 0;
        for (uint8 prop = 0; prop < proposals.length; prop++) 
            if (proposals[prop].voteCount > winningVoteCount) {
                winningVoteCount = proposals[prop].voteCount;
                _winningProposal = prop;
            }
       assert(winningVoteCount>=1);
    }
}
