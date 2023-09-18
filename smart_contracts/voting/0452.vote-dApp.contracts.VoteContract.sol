//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract VoteContract{

  uint data;

  function getData() external view returns(uint){
    return data;
  }

  function setData(uint _data) external {
    data = _data;
  }

  function incrementData(uint _data) private {
    data = _data + 10;
  }
}
