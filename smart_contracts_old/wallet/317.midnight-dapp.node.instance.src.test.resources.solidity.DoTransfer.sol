pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
contract DoTransfer {
    event Transferred(uint value, address from, address to);

    function transferTo(address payable other) public payable {
        other.transfer(msg.value);
        emit Transferred(msg.value, msg.sender, other);
    }
}
