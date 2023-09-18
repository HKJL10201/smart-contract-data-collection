// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract Vote {
    
    struct Candidate {
        uint votes;
        bool registered;
    }

    address private owner;
    mapping(address => bool) public registeredVoters;
    mapping(address => bool) public voteCasted;
    mapping(address => Candidate) public candidates;

    uint public highestVotes;
    address winner;
    
    constructor(address _owner) {
        owner = _owner;
    }

    function registeredVoter() public {
        if(registeredVoters[msg.sender] == true){
         revert("Already registered");
         }
        registeredVoters[msg.sender] = true;
    }


    function registerCandidate() public {
        if(candidates[msg.sender].registered){
            revert("Already a candidate");
        }
        candidates[msg.sender] = Candidate(0,true); 
    }
    

    function castVote(address candidate) public{
        if(!registeredVoters[msg.sender]){
         revert("Not a registered voter!");
         }
        if(voteCasted[msg.sender]){
             revert("Already voted!");
         }
        if(candidates[msg.sender].registered){
             revert("Candidates can't vote!");
         }
        if(!candidates[candidate].registered){
            revert("Not a candidate!");
        }
        
        candidates[candidate] = Candidate(candidates[candidate].votes + 1, true);
        voteCasted[msg.sender] = true;

        if(candidates[candidate].votes > highestVotes){
            highestVotes = candidates[candidate].votes;
            winner = candidate;
        }
    }

    function endVoting() public view returns(address){
        if(msg.sender != owner){
            revert("Only owner of the contract can end voting!");
        }
        return winner;
    }


}