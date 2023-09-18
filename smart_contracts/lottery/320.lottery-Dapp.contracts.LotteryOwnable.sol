pragma solidity ^0.4.19;

contract LotteryOwnable {

  address public owner;

  function ownable () public returns(address) {
  	owner = msg.sender;
  	return(owner);
  }

   modifier onlyOwner() {
   require(msg.sender == owner);
   _;
  }
}