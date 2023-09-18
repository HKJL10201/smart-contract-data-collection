// SPDX-License-Identifier: MIT//
pragma solidity >=0.5.0 <0.7.0;

contract VotePT {

  struct Voter {
      uint count;
      string id;
      uint8 party;
  }

  mapping(address => bool) public electors;
  mapping(uint => Voter) public voters;
  uint public voteCount;
  uint[] public parties;

  //Voters can either vote for a party or perform a blank vote
  //There is a total of 10 parties + the blank vote
  function vote(string memory _id, uint8 _party, address  _voter) public {
      require(bytes(_id).length == 8, 'Please insert a valid ID number');
      require(_party >= 0 && _party <= 10, "Please insert a number according to the list");
      require(msg.sender == _voter, 'Only owner address');
      require(!electors[msg.sender], "You have already voted"); //if true the person already voted
      voteCount++;
      electors[msg.sender] = true;
      voters[voteCount] = Voter(voteCount, _id, _party);
      parties.push(_party);
  }

  function getAllVotes() public view returns (uint) {
      return voteCount;
  }

  function getVotesByParty (uint _party) public view returns (uint) {
    uint count = 0;
    for(uint i = 0; i < parties.length; i ++){
        if (parties[i] == _party) {
            count++;
        }
    }
    return count;
  }
}