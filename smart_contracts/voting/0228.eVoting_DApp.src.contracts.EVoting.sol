// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

contract EVoting {
    string public dapp_name;
    string public elector;
    uint public id = 0;
    uint public voteCount = 0;
    uint public voteChoice = 0;
    uint public votesNumber = 0;
    uint public candidateID = 0;

    mapping(uint => Vote) public votes;
    mapping(uint => Candidate) public candidates;

    constructor() {
        dapp_name= "eVoting DApp";
        candidates[0] = Candidate(0, "Null Vote", "", 0);
    }

    event Voted (
        uint id,
        address elector,
        uint voteChoice
    );

    event Candidated (
      uint candidateID,
      string name,
      string politicalSide,
      uint votesNumber
    );

    struct Vote {
        uint id;
        address elector;
        uint voteChoice;
    }

    struct Candidate {
      uint candidateID;
      string name;
      string politicalSide;
      uint votesNumber;
    }

    function candidateYourself(string memory _name, string memory _politicalSide) public {
      require(bytes(_name).length > 0);
      candidateID++;
      candidates[candidateID] = Candidate(candidateID, _name, _politicalSide, 0);
      emit Candidated(candidateID, _name, _politicalSide, 0);
    }

    function createVote(uint _voteChoice) public {
        //choices will be from candidate 1 to candidate X. 0 is the default value, means no vote yet
        require(candidateID >= _voteChoice);
        //increment count
        voteCount++;
        candidates[_voteChoice].votesNumber += 1;
        //create new vote
        votes[voteCount] = Vote(voteCount, msg.sender, _voteChoice);
        //trigger event
        emit Voted(voteCount, msg.sender, _voteChoice);
    }

}

// transaction cost 351562 gas      execution cost 217846 gas
