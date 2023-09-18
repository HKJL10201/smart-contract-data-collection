// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract call {
    function arbitraryCall(address recipient, uint amount, bytes memory data) public {
        (bool success, ) = recipient.call{value: amount}(data);
        require(success, "Fail");
    }
}
