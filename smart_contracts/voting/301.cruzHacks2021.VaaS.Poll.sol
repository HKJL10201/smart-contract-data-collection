// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

contract Measure24 {

    address owner; 

    //keep a tally of the total votes
    uint public voteCount = 0;
    string public measureTitle = "California Proposition 24. Expand Consumer Privacy";
    string public description = "Allows consumers to prevent businesses from sharing personal information, correct inaccurate personal information and limit businesses’ use of sensitive personal information including precise geolocation, race, ethnicity and health information.";
   
    constructor() public {
        //set the owner to the deployer of the contract
        owner = msg.sender;
    }

    //function modifier that restricts function to be run by the owner
    modifier restrictToOwner(){
        require(msg.sender == owner);
        _;
    }

    //Vote object. Contains the vote choice, the id, and an identifier
    struct Vote {
        string choice;
        string uid;
        bool isValue;
    }

    //hash map of the voter's ID to their Vote
    mapping(string => Vote) public votesById;

    //hash map from number of votes cast to Vote
    mapping(uint => Vote) public votesByOrder;

    
    function castVote(string memory _id, uint x) restrictToOwner public {
        string memory _choice;
        if(x == 0){
            _choice = "no";
        }else if(x == 1){
            _choice = "yes";
        }else{
            revert();
        }

        //check to see if vote had been cast already
        if(votesById[_id].isValue){
            revert();
        }
        
        //create a new vote with passed data
        Vote memory currentVote = Vote(_choice, _id, true);

        //increase the total vote count
        voteCount++;
        //write vote to hashmaps
        votesById[_id] = currentVote;
        votesByOrder[voteCount] = currentVote;
    }
}