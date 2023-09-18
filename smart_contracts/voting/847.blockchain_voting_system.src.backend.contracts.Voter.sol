// SPDX-License-Identifier:GPL-3.0

pragma solidity ^0.8.17;
import "./Leader.sol";







contract Voter is Leader {

    uint public noOfVoters;
    
    struct Citizen{
        uint id;
        address addr;
        bool isVoted;
    }

    Citizen [] public allCitizens;
    mapping(address => Citizen) public citizens;
    mapping(address => bool) public voters;

    // Event for adding the Citizen
    event AdditionOfCitizen(address _owner,address _participant,Citizen _citizen);
    // Event for voting a particular participant
    event VotedforParticipant(address _participant,address _voter,Citizen _citizen);

    constructor(){
        noOfVoters = 0;
    }


    function addCitizen(address _addr)external onlyOwner{
        require(voters[_addr]==false,"This address is already in the Voters List");
        citizens[_addr] = Citizen(noOfVoters,_addr,false);
        voters[_addr] = true;
        allCitizens.push(citizens[_addr]);
        emit AdditionOfCitizen(owner,_addr,citizens[_addr]);
        noOfVoters = noOfVoters +1;
    }

    function voteLeader(address _leader) external{
        // The Voter should not vote to him/herself
        require(msg.sender != _leader,"Self Voting cannot take place");
        // Check the voter is a citizen 
        require(citizens[msg.sender].addr==msg.sender,"This address is not in our citizen list contact admin/owner");
        // To take out duplicate votes
        require(citizens[msg.sender].isVoted==false,"Duplicate votes cannot be done");
        // Check the voter is in the voters list
        require(voters[msg.sender]==true,"This address is not in the voters list contact admin/owner");
        // Add this guys vote to the selected Leader
        noOfLeaderVotes[_leader] = noOfLeaderVotes[_leader] +1;
        // Change the state of the voter
        Citizen storage vote  = citizens[msg.sender];
        vote.isVoted = true;
        emit VotedforParticipant(_leader, msg.sender, vote);
    }
}