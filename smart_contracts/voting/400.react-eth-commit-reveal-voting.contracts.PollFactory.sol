// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Poll.sol";

contract PollFactory {
  address[] public deployedPolls;
  
  event deployedContract(address _address);
  
  function createNewPoll(string memory _details) public returns(address) {
    //Deploy a new poll
    Poll newPoll = new Poll(_details, msg.sender);
    //Get the address
    address pollAddress = address(newPoll);
    deployedPolls.push(pollAddress);
    emit deployedContract(pollAddress);
    return pollAddress;
  }

  function getPolls() public view returns(address[] memory) {
      return deployedPolls;
  }
}
