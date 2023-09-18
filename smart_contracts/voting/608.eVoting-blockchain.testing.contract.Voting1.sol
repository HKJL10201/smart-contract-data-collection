pragma solidity ^0.7.0;
//SPDX-License-Identifier: <UNLICENSED>
pragma experimental ABIEncoderV2;
contract Voting {
    
    //Structure for voter
    struct Voter {
        uint vote; // access to vote
        bool voted; // voted or not
        uint vote_index; // vote no/index
    }
    struct Candidates {
    // string name    
    string name; //name of each candidate 
    uint votecount; //number of accumulated votes
    }
    // array defined for candidates
    Candidates [] public candidate_list;

    // we need to map  voters to address, it allows us to create a store value with keys and indexes
    mapping (address => Voter) public voters; // voters get address as a key and voter for value

    address public chairman  ;
// add candidate list to smart contract
    constructor(string[] memory CandidatesNames){
        // memory - temporary  vs storage - permanent 
        // msg.sender  is a global variable that state the person who is currently connecting to the contract
        chairman = msg.sender;

        voters[chairman].vote_index = 1;
        
        for(uint i=0; i < CandidatesNames.length; i++) {
            candidate_list.push(Candidates({
                name : CandidatesNames[i],
                votecount: 0
            }));
        }      
    }

    // function to authenticate voter
    function RightToVote(address voter) public {
        require(msg.sender == chairman,
                'Chairman will give access to vote');
                 //voter hasn't voted yet
        require(!voters[voter].voted,
                'You have already voted');
        require(voters[voter].vote_index == 0);

        voters[voter].vote_index = 1; // give voter right to vote
            // here vote count is checking in
    }

    // function for voting
    function vote(uint candidates) public{
        Voter storage sender = voters[msg.sender];
        require(sender.vote_index != 0, 'You are not allowed to vote');
        require(!sender.voted, 'Already voted');
        sender.voted = true;
        sender.vote = candidates; 

        candidate_list[candidates].votecount += sender.vote_index;
        
   }
    // function to show results
    function winnerCandidate() public view returns (uint winningCandidate_votes ){
        uint winningVoteCount=0;
        for(uint i =0; i < candidate_list.length; i++) {
             if(candidate_list[i].votecount > winningVoteCount){
                 winningVoteCount = candidate_list[i].votecount;
                 winningCandidate_votes = i;
             } 
        }
    }

    function winner() public view returns (string memory winnerName) {
        winnerName = candidate_list[winnerCandidate()].name;
    }
}