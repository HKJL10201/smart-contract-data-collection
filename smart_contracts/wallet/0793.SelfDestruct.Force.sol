// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Force {
    
    address payable owner;
    address payable recipient;

    constructor(address payable _recipient) {
        owner = payable(msg.sender);
        recipient = _recipient;
    }

    receive() external payable {}

    function destroy() public {
        require(msg.sender == owner);
        selfdestruct(recipient);
    }
}
