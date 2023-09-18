// SPDX-License-Identifier: MIT

pragma solidity 0.6.1;
pragma experimental ABIEncoderV2;

contract CeloVoting { 
  struct BallotCandidate {
    string name;
    string party;
    uint voteCount;
    uint creationDate;
    uint expirationDate;
  }

  BallotCandidate[] public candidates;
  address public manager;
  string public votingDistrict;
  uint public candidatesLength = 0;
  mapping (address => bool) public voters;

  modifier restricted {
    require(msg.sender == manager, "Manager Only Function");
    _;
  }

  constructor (
    string[] memory _candidateNames,
    string[] memory _candidateParty,
    string memory _district,
    address _manager,
    uint _amountofHours
  ) public {
    manager = _manager;
    votingDistrict = _district;
    for(uint i = 0; i < _candidateNames.length; i++) {
      candidatesLength++;
      candidates.push(BallotCandidate({   
        name: _candidateNames[i],
        party: _candidateParty[i],
        voteCount: 0,
        creationDate: now,
        expirationDate: now + _amountofHours
      }));
    }
  }

  function vote(
    uint _index
  ) public {
    require(! voters[msg.sender], "You can only vote once");

    // if(now > candidates[_index].expirationDate) {
    //   revert();
    // }

    candidates[_index].voteCount++;
    voters[msg.sender] = true;
  }

  function getCandidateName(
    uint _index
  ) restricted public view returns(
    string memory name
  ) {
    require(now > candidates[_index].expirationDate, "Kindly wait till after expiration date");
    return candidates[_index].name;
  }

  function getCandidateParty(
    uint _index
  ) restricted public view returns(
    string memory party
  ) {
    require(now > candidates[_index].expirationDate, "Kindly wait till after expiration date");
    return candidates[_index].party;
  }

  function getVoteCount(
    uint _index
  ) restricted public view returns(
    uint voteCount
  ) {
    // require(now>candidates[_index].expirationDate);
    return candidates[_index].voteCount;
  }
}