
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vote{
 
struct Candidate{  //Politician
    
    
    uint id;
    string name;
    uint votes;
    string party;
    string qualification;
    string imageurl;

    
}

struct Voters{
 address vaddress;   
}


uint public candidatescount;
address public manager;
uint public voterscount;

mapping(uint=>Candidate) public candidates;


mapping(address=>bool)public voted; //checks if person has already voted
mapping(uint=>Voters) public voters;


    event electionupdate(
        uint id,
        string name,
        uint votes,
        string party,
        string qualification,
        string imageurl
        );
        
    constructor(){
    manager=msg.sender;
}

  function addcandidate(string memory name,string memory party,string memory qualification,string memory imageurl) public{
      
  require(msg.sender==manager);
    candidatescount++;
    candidates[candidatescount]=Candidate(candidatescount,name,0,party,qualification,imageurl); //storing in map with id as count
    
   }



function vote(uint _id) public
{
    require(msg.sender!=manager);
    require(!voted[msg.sender],"You have already voted");
    
    candidates[_id].votes++;
    
    voted[msg.sender]=true;
    voterscount++;
    voters[voterscount]=Voters(msg.sender);
    
    emit electionupdate(_id,candidates[_id].name,candidates[_id].votes,candidates[_id].party,candidates[_id].qualification,candidates[_id].imageurl);
    
}


    
}

