// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Caller {

    error CallFailed(string message);
    function arbitraryCall(address recipient, uint value, bytes memory data) public {
    (bool success, ) = recipient.call{value: value}(data);
    if (!success) {
        revert CallFailed("Call Failed");
    }

    }
}
