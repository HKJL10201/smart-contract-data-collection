// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract OwnerAble {

  address private ownerAddress;

  constructor() {
    ownerAddress = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == ownerAddress, 'caller is not the owner.');
    _;
  }

  function setOwner(address _address) public onlyOwner() {
    ownerAddress = _address;
  }

  function owner() public view returns (address) {
    return ownerAddress;
  }

}