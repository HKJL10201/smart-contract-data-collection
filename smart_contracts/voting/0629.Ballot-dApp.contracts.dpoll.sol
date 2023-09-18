// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//creating a voting contract

// we need to accept proposals and store them
//proposal: their name, number

//voters and voting ability
//1.voters and voting ability
//2.keep track of voting

//3. chairperson
//authenticate and deploy contract

contract Ballot {
    //string and uint is a datatype

    //creating our own datatype structure

    //voters: voted=bool, access to vote=uint, vote index = unit

    struct Voter {
        uint vote;
        bool voted;
        uint weight;
    }

    struct Proposal {
    bytes32 name; //name of each proposal
    uint voteCount; //number of accumulated votes
    }

    Proposal[] public proposals;

    // mapping allows us to create a store value with keys and indexes

    mapping(address => Voter) public voters; //voters get address as a key and voter for value

    address public chairperson;

    constructor(bytes32[] memory proposalNames) {

        chairperson = msg.sender;

        //add 1 to chairperson weight
        voters[chairperson].weight =1;


        // this will add the proposal names to the smart contract upon development
        for(uint i=0; i < proposalNames.length; i++ ) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));

        }
 
    }

    // we would function to authenticate votes

    function giveRightToVote(address voter) public {
        require(msg.sender == chairperson,
                'only the chairperson can give access to vote');
                // require that the voter hasn't voted yet
                require(!voters[voter].voted,
                'The voter has already voted');
                require(voters[voter].weight == 0);

                voters[voter].weight = 1;
        
    }

    // function for voting
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, 'Has no right to vote');
        require(!sender.voted, 'Already voted');
        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].voteCount += sender.weight;
    }


    // functions for showing results



    // function that shows the winning proposal by integer

        function winningProposal() public view returns (uint winningProposal_) {

            uint winningVoteCount = 0;
            for(uint i = 0; i < proposals.length; i++) {
                if(proposals[i].voteCount > winningVoteCount) {
                    winningVoteCount = proposals[i].voteCount;
                    winningProposal_ = i;
                }
            }
        }

    //function that shows the winner by the name

    function winningName() public view returns (bytes32 winningName_) {

        winningName_ = proposals[winningProposal()].name;

    }

}