// Franklin Holguin
// Software Engineer
// www.franklinholguin.com

// SPDX-License-Identifier: MIT
pragma solidity  >=0.7.0<0.9.0;

contract Ballot {
    
    // struct is method to create your own data

    // voters: voted = bool, access to vote = uint , vote index = unit
    
    struct Voter {
        uint vote;
        bool voted;
        uint weight;
    }



    struct Proposal {

    bytes32  name; // the name of each proposal
    uint voteCount; // number of accumulated votes
    }

    Proposal[] public proposals;

    // mapping allows for us to create a store value with keys and indexes
    mapping(address => Voter) public  voters; // voters get address as a key and voters for value   

    address public chairperson;

    constructor(bytes32[] memory proposalNames){
        //memory define a temporary data location in solidity durin runtime only
        // we guarantee space for it
        
        // mgs.sender = is a global variable that states the person
        // who is currently connectiong to the contract
        chairperson = msg.sender;

        // add 1 to chairperson wight
        voters[chairperson].weight = 1;

        // will add the proposal names to the smart contracy upon deployment
        for (uint i=0; i < proposalNames.length; i++){
            proposals.push(Proposal({
                name: proposalNames[i], 
                voteCount: 0
            }));
        }

    }

    // function for authenticate votes

    function giveRightToVote(address voter) public  {
        require(msg.sender == chairperson, 
            "Only chairperson can give right to vote.");
            // require that the voter hasn't voted yet
        require(!voters[voter].voted,
            "The voter already voted.");
        require(voters[voter].weight == 0);
        
        voters[voter].weight = 1;    
    }

    //function for voting

    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;


        // If 'proposal' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[proposal].voteCount += sender.weight;

    }

    //funtion for showing the results

    // 1. fusnctio tha t shows rhe winning proposal by interger

        function winningProposal() public view returns(uint winningPorposal_){
            
            uint winningVoteCount = 0;
            for(uint i =0; i < proposals.length; i++){
                if(proposals[i].voteCount > winningVoteCount){
                    winningVoteCount = proposals[i].voteCount;
                    winningPorposal_ = i;

                }
            }

        }

    // 2. function that shows the winner by name

    function winingName() public view returns (bytes32 winningNAme_){
        
        winningNAme_= proposals[winningProposal()].name;
    }
}
