// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

    
contract Evoting{
    address public userAddress;

    string [4]registeredVoters;
    
    



    function Vote(userAddress, _ifelseCheck, hasVoted) public view 
    {   
        if(!hasVoted){

            owner = msg.sender;
            registeredVoters.push(userAddress); 
            hasVoted = true;
            function addCandidate(string memory _name) public {
                candidates.push(Candidate({
                name: _name,
                voteCount: 0
            }));
        }
        else{
            console.log("You have already voted.");
        }
        

    }

    
}