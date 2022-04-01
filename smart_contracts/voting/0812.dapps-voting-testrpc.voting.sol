pragma solidity ^0.4.11;

contract Voting {

  mapping (bytes32 => uint8) public votes;
  bytes32[] public party_n;
  address owner;
  mapping (address => uint8) public votes_limit;

  function Voting(bytes32[] party) {
    party_n = party;
    owner = msg.sender;
  }

  function count(bytes32 party) returns (uint8) {
    if (valid(party) == false) throw;
    return votes[party];
  }

  function vote(bytes32 party) {
    if (valid(party) == false) throw;
    if (votes_limit[msg.sender] == 1) throw;
    votes[party] += 1;
    votes_limit[msg.sender] += 1;
  }

  function valid(bytes32 party) returns (bool) {
    for(uint i = 0; i < party_n.length; i++) {
      if (party_n[i] == party) {
        return true;
      }
    }
    return false;
  }

  function kill() {
    if(msg.sender == owner) selfdestruct(owner);
  }
}
