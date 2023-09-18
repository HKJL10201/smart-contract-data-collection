// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0 <0.9.0;

//declaring a contract
contract Election{

    //Model a candidate
    struct Candidate{
        uint id;
        string name;
        uint voteCount;
        uint maxi;
        string name_;
    }

    uint  maxx = 0;
    string name;

    //store account that have voted
    mapping(address => bool) public voters;
    //store candidates
    //Fetch candidates
    mapping(uint => Candidate) public candidates;

    //State variable that store a candidates count : Keep track of how many candidates exist in mapping  
    uint public candidatesCount;

    //voted Event
    event votedEvent(
        uint indexed _candidateId
    );

    //Contructor
    constructor () public {
        addCandidate("Suresh Choudhary : Bharatiya Janata Party (BJP)");
        addCandidate("Dhanashree Kedari : Aam Aadmi Party (AAP)");
        addCandidate("Yukta Sachdev  : Indian National Congress ");
        addCandidate("Kshitij Shitole  : Nationalist Congress Party");
    }

    function addCandidate(string memory _name) private {
        //Increment candidate count it represent ID 
        candidatesCount++;
     
      
        //Create a candidate by passing key as candiadateCount and assign a model(structure) of candidates correspond to key
        candidates[candidatesCount] = Candidate(candidatesCount , _name , 0,0,"xx");
    }

    function vote (uint _candidateId) public{

        //require that account haven't voted before
        require(!voters[msg.sender]);

        //require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount );

        //record that voter has voted
        //access account who is voting by (msg.sender)
        voters[msg.sender]= true;

        //Update candidate vote count
        //We reference our candidate from mapping and read value of the candidate 
        //struct that we are trying to vote for and increment votecount of 
        //respective candidate

        candidates[_candidateId].voteCount ++;
        
              if(candidates[_candidateId].voteCount> maxx){
                  maxx = candidates[_candidateId].voteCount;
          candidates[_candidateId].maxi = candidates[_candidateId].voteCount;
           candidates[_candidateId].name_ = candidates[_candidateId].name;
            } 

        //trigger voted event
        emit votedEvent(_candidateId);
    }
}