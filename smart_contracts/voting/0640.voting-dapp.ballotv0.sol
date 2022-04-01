pragma solidity ^0.4.0;
contract Ballot {

    struct Voter {
        uint weight;
        bool voted;
        uint8 vote;
        address delegate;
    }
    struct Proposal {
        uint voteCount;
    }
    uint voteCount=0;
    address chairperson;
    mapping(address => Voter) voters;
    Proposal[] proposals;

    
    uint startTime;
    //modifiers
   modifier onlyBy(){
   require(msg.sender==chairperson);
   _;
   }
   function() external payable{}
   event voting(uint a);


    /// Create a new ballot with $(_numProposals) different proposals.
    constructor(uint8 _numProposals) public  {
        require(_numProposals>0);
        chairperson = msg.sender;
        voters[chairperson].weight = 2; // weight is 2 for testing purposes
        proposals.length = _numProposals;
        startTime = now;
    }
    

    /// Give $(toVoter) the right to vote on this ballot.
    /// May only be called by $(chairperson).
    function register(address toVoter) public payable onlyBy() {
        //if (stage != Stage.Reg) {return;}
        if (msg.sender != chairperson || voters[toVoter].voted) return;
        voters[toVoter].weight = 1;
        voters[toVoter].voted = false;
        voting(voteCount++);
    }

    /// Give a single vote to proposal $(toProposal).
    function vote(uint8 toProposal) public  {
       // if (stage != Stage.Vote) {return;}
       
        Voter storage sender = voters[msg.sender];
        require (sender.vote==1 && !sender.voted || toProposal < proposals.length);
        sender.voted = true;
        sender.vote = toProposal;   
        proposals[toProposal].voteCount += sender.weight;       
        
    }

    function winningProposal() public constant returns (uint8 _winningProposal) {
       //if(stage != Stage.Done) {return;}
        uint256 winningVoteCount = 0;
        for (uint8 prop = 0; prop < proposals.length; prop++)
            if (proposals[prop].voteCount > winningVoteCount) {
                winningVoteCount = proposals[prop].voteCount;
                _winningProposal = prop;
            }

    }
    function getVoterDetails(address ad) public returns(uint weight,uint8 vote,bool voted){
        Voter storage sender=voters[msg.sender];
        weight=sender.weight;
        vote=sender.vote;
        voted=sender.voted;
    }
}


