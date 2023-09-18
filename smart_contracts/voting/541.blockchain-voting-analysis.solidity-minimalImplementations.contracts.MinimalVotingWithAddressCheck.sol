pragma solidity 0.5.8;

contract MinimalVotingWithAddressCheck {
  mapping(uint256 => uint256) public votes;

  mapping(address => bool) eligibleVoters; 

  address payable owner;

  constructor() public {
  	owner = msg.sender;
  }

  function authorize(address _voter) public {
  	require(msg.sender == owner);

  	eligibleVoters[_voter] = true;
  }

  function vote(uint256 _number) public {
  	require(eligibleVoters[msg.sender]);
  	eligibleVoters[msg.sender] = false;

    votes[_number]++;
  }
}