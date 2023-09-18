pragma solidity 0.5.8;

contract MinimalVotingWithHashTokenCheck {
  mapping(uint256 => uint256) public votes;

  mapping(bytes32 => bool) publicTokens; 

  address payable owner;

  constructor() public {
  	owner = msg.sender;
  }

  function authorize(bytes32 _publicToken) public {
  	require(msg.sender == owner);

  	publicTokens[_publicToken] = true;
  }

  function vote(uint256 _number, bytes32 _privateToken) public {
  	bytes32 hash = keccak256(abi.encodePacked(_privateToken));
  	require(publicTokens[hash]);
  	publicTokens[hash] = false;

 	votes[_number]++;
  }
}
