// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "./Candidates.sol";
contract Voters {
    struct Voter {
        bool canVote;
        bool voted;  // if true, that person already voted
        uint vote;   // index of the voted proposal
    }
    // Voter public voter;
    address owner;
    mapping(address => Voter) public voters;
    constructor(){
       owner = msg.sender;
        // candidates.call(bytes4(sha3("castVote(uint)")),candidateIndex);
    }
    function vote(address candidatesContractAddress,uint candidateIndex) public{
        require(voters[msg.sender].canVote==true,"No Acces to vote");
        require(voters[msg.sender].voted!=true,"Already voted, Cant vote again");
        // (bool success,bytes memory data) = candidatesContractAddress.call(abi.encodeWithSignature("castVote(uint)", candidateIndex));    

        // require(success,"Voting to candidates from failed");
        Candidates temp;
        temp = Candidates(candidatesContractAddress);    
        temp.castVote(candidateIndex);
        voters[msg.sender].vote = candidateIndex;
        voters[msg.sender].voted = true;
    }
    function giveAccessToVote(address voterAccountAddress) public {
        require(voters[voterAccountAddress].voted==false,"Already voted");
        require(voters[voterAccountAddress].canVote!=true,"Already access to vote");
        voters[voterAccountAddress].canVote = true;
    }
}