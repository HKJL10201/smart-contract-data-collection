

//jshint ignore: start

pragma solidity ^0.4.11;

contract Ownable {
  
  address public owner;
  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function Ownable() {
    owner = msg.sender;
  }
  
  function transferOwnership(address _owner) onlyOwner {
    owner = _owner;
  }
  
  function withdraw(address _dest) onlyOwner {
    _dest.transfer(this.balance);
  }
  
}

//jshint ignore: end