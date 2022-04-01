//SPDX-Licence-Identifier: MIT

pragma solidity >=0.8.7;

contract SendEth {
    function sendViaCall(address payable _to) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        if (msg.value > 1 ether) {
            (bool sent, bytes memory data) = _to.call{value: msg.value}("");
            require(sent, "Failed to send Ether");
        } else {
            revert("You need to send at least 1 ether");
        }
    }
}