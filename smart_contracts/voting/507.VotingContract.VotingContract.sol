// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

contract Ballot {
   
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        uint vote;   // index of the voted proposal
    }

    struct Candidate {
        string name;    
        uint voteCount; 
    }

    address public ElectionOnwer;

    mapping(address => Voter) public voters;

    Candidate[] public candidates;
    
    enum State { Created, Voting, Ended } 
    
    State public state;

    constructor(string[] memory candidateNames) {
        ElectionOnwer = msg.sender;
        voters[ElectionOnwer].weight = 1;
        state = State.Created;
        
        for (uint i = 0; i < candidateNames.length; i++) {
            candidates.push(Candidate({
                name: candidateNames[i],
                voteCount: 0
            }));
        }
    }
    
    // MODIFIERS
    modifier OnlyElectionOnwer() {
        require(
            msg.sender == ElectionOnwer,
            "Only ElectionOnwer can start and end the voting"
        );
        _;
    }
    
    modifier CreatedState() {
        require(state == State.Created, "it must be in Started");
        _;
    }
    
    modifier VotingState() {
        require(state == State.Voting, "it must be in Voting Period");
        _;
    }
    
    modifier EndedState() {
        require(state == State.Ended, "it must be in Ended Period");
        _;
    }
    
    
   
    function startVote() 
        public
        OnlyElectionOnwer
        CreatedState
    {
        state = State.Voting;
    }
    
  
    function endVote() 
        public 
        OnlyElectionOnwer
        VotingState
    {
        state = State.Ended;
    }
    
    
    
    function AuthorizedToVote(address voter) public {
        require(
            msg.sender == ElectionOnwer
        );
        require(
            !voters[voter].voted
        );
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

   
    function vote(uint candidate) 
        public
        VotingState
    {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = candidate;

       
        candidates[candidate].voteCount += sender.weight;
    }

    function winningCandidate() 
        public
        EndedState
        view
        returns (string memory winnerName_ ,uint voteCount_ )
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < candidates.length; p++) {
            if (candidates[p].voteCount > winningVoteCount) {
                winningVoteCount = candidates[p].voteCount;
                winnerName_ = candidates[p].name;
                voteCount_ = candidates[p].voteCount;

            }
        }
    }
}