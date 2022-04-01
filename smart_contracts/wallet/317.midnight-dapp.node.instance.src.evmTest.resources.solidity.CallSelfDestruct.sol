pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
contract CallSelfDestruct {

  function callDestruct() public {
    CallSelfDestruct firstCall = CallSelfDestruct(this);
    firstCall.doSelfdestruct();

    CallSelfDestruct secondCall = CallSelfDestruct(this);
    secondCall.doSelfdestruct();
  }

  function doSelfdestruct() public {
    selfdestruct(payable(msg.sender));
  }

}
