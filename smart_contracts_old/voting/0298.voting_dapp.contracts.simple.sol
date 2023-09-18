pragma solidity ^0.4.0;
contract simple {

voter[] public people;
address client;
mapping (address=>uint) linkr;
struct voter {

  uint age;
  uint aadhaar;
  bytes32 name;

}

party[] public parties;

struct party {

  bytes32 party_name;
  bytes32 candidate_name;
  uint votes_number;

}

function simple() {
 client = msg.sender;
}

modifier ifeligible(uint _age_){

 if(_age_ < 18 ){
   throw;
 }
 else{
   _;
 }
}

function add_people(bytes32 _name,uint _age, uint _aadhaar,address _user) ifeligible(_age) returns (bool success) {

  voter memory new_voter;
  new_voter.name = _name;
  new_voter.aadhaar = _aadhaar;
  new_voter.age = _age;
linkr[_user]=_aadhaar;
  people.push(new_voter);
  return true;
}

function get_people() constant returns (bytes32[],uint[],uint[]) {

  uint length = people.length;

  bytes32[] memory names = new bytes32[](length);
  uint[] memory aadhaars = new uint[](length);
  uint[] memory ages = new uint[](length);

  for (uint i = 0; i < people.length; i++){
    voter memory current_voter;
    current_voter = people[i];

    names[i] = current_voter.name;
    ages[i] = current_voter.age;
    aadhaars[i] = current_voter.aadhaar;
  }

  return (names,ages,aadhaars);

}

function add_party(bytes32 _party_name, bytes32 _candidate_name) returns (bool success) {

  party memory new_party;
  new_party.party_name = _party_name;
  new_party.candidate_name = _candidate_name;
  new_party.votes_number = 0;

  parties.push(new_party);
  return true;

}

function get_party() constant returns (bytes32[], bytes32[]) {

  uint length = parties.length;

  bytes32[] memory party_names = new bytes32[](length);
  bytes32[] memory candidate_names = new bytes32[](length);

  for (uint i = 0; i < parties.length; i++){
    party memory current_party;
    current_party = parties[i];

    party_names[i] = current_party.party_name;
    candidate_names[i] = current_party.candidate_name;
  }

  return (party_names, candidate_names);

}

function votes(bytes32 _party_to_give_vote,address _user) returns (bytes32) {

  for (uint j = 0; j < parties; j++){

    party memory temp_party;
    temp_party = parties[j]

    if(_party_to_give_vote == temp_party.party_name){

      temp_party.votes_number++;

    }
    else{
      return ("error");
    }

  }

}

function get_votes() constant returns (bytes32[], uint[]){

  uint length = parties.length;

  bytes32[] memory party_names = new bytes32[](length);
  bytes32[] memory votes_numbers = new bytes32[](length);

  for (uint k = 0; k < parties.length; k++){
    party memory current1_party;
    current1_party = parties[i];

    party_names[i] = current1_party.party_name;
    votes_numbers[i] = current1_party.votes_numbers;
  }

  return (party_names, votes_numbers);

}

}
