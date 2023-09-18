// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Ownable {

  address private owner;

  constructor() public {
    owner = msg.sender;
  }

  event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    _setOwner(_newOwner);
  }

  function renounceOwnership() public onlyOwner {
    _setOwner(address(0));
  }

  function _setOwner(address _newOwner) private {
    address oldOwner = owner;
    owner = _newOwner;
    emit OwnershipTransferred(oldOwner, _newOwner);
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
}
