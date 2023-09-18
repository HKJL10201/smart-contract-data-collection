pragma solidity 0.5.8;

contract MinimalVoting {
  mapping(uint256 => uint256) public votes;

  function vote(uint256 _number) public payable {
    votes[_number]++;
  }
}