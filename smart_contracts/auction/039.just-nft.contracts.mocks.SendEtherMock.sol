// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// SendEther mock contract
contract SendEtherMock {
    function sendViaTransfer(address payable _to) public payable {
        _to.transfer(msg.value);
    }

    function sendViaSend(address payable _to) public payable returns (bool) {
        bool sent = _to.send(msg.value);
        return sent;
    }

    function sendViaCall(address payable _to) public payable returns (bool) {
        (bool sent, ) = _to.call{value: msg.value}("");
        return sent;
    }
}
