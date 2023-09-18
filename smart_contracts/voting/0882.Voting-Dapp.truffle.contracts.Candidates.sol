// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import './AllVoter.sol';
contract Candidates{
    /* 
    there gonna be a pre-vote and a final vote.
    So, the pre-vote for candidate selections and the final vote for the actual election.
    In pre-vote, anyone can be a candidate with a valid NID and a ammount of money.
    In final vote, only the winner 3 candidate can be the real candidates for the final  vote.

    */ 

    
    
    // We need a struct to store the candidate details
    struct Candidate{
        uint id;
        string logo;
    }

    // We need a mapping to store the candidates
    mapping(address => Candidate) public candidates;
    address[] public candidateList;

    // We need a variable to store the candidates count
    uint public candidatesCount;

    //events
    event candidateAdded(address indexed candidateAddress, uint indexed NID, string logo);
    constructor(){

    }

    // We need a function to add a candidate
    function addCandidate(uint _NID, string memory _logo) public payable{
        //Check if the candidate is already added?
        // require(keccak256(abi.encodePacked(candidates[msg.sender].id))  == keccak256(abi.encodePacked("")), "Candidate already added");
        require(candidates[msg.sender].id == 0, "Candidate already added");

        //Check the ammount of money is valid?
        require(msg.value == 100000000000000000, "You need to pay 1 ether to be a candidate");



        //Add the candidate
        candidatesCount++;
        candidates[msg.sender] = Candidate(_NID, _logo);
        candidateList.push(msg.sender);

        emit candidateAdded(msg.sender, _NID, _logo);
    }


    

}