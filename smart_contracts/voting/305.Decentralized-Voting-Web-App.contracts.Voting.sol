pragma solidity ^0.5.0;

library CandidateLib{
    struct Candidate{
        uint256 votes;
    }

    function getVotes(Candidate storage candidate) public view returns(uint256) {
        return candidate.votes;
    }

    function addVote(Candidate storage candidate) public {
        candidate.votes++;
    }
}

contract Voting {
   CandidateLib.Candidate candidate1;
   CandidateLib.Candidate candidate2;
    bool private stopped = false;

   uint256 start = 0;
   bool isVotingInitiated = false;

   mapping(address => bool) public voted;

   address owner;

   constructor() public {
        owner = msg.sender;
    }

    modifier stopInEmergency {
        require(!stopped);
        _;
    }

   modifier OnlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function stopContract() OnlyOwner private{
        stopped = !stopped;
    }

     modifier NotVoted(){
        require(voted[msg.sender]!=true);
        _;
    }

    modifier VoteOngoing{
        require(now < start + 4 minutes);
        _;
    }

    modifier VoteEnded{
        require(now >= start + 4 minutes);
        _;
    }

    modifier VoteStarted{
        require(start!=0);
        _;
    }

    modifier VoteNotStarted{
        require(start==0);
        _;
    }

   function startVote() OnlyOwner VoteNotStarted stopInEmergency public{
        start = now;
        isVotingInitiated = true;
   }

   function addCandidate1Vote() NotVoted VoteStarted VoteOngoing stopInEmergency public {
       voted[msg.sender] = true;
        CandidateLib.addVote(candidate1);
   }

   function addCandidate2Vote() NotVoted VoteStarted VoteOngoing stopInEmergency public{
       voted[msg.sender] = true;
       CandidateLib.addVote(candidate2);
   }

   function getCandidate1Votes() VoteEnded public view returns(uint256) {
       return CandidateLib.getVotes(candidate1);
   }

   function getCandidate2Votes() VoteEnded public view  returns(uint256) {
       return CandidateLib.getVotes(candidate2);
   }

    function getIsVotingInitiated() public view returns(bool){
        return isVotingInitiated;
    }

    function isContractStopped() public view returns(bool){
        return stopped;
    }
}