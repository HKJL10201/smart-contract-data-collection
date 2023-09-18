//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;


contract Sender {
    receive() external payable {}

    function withdrawTransfer(address payable _to) public {
        _to.transfer(10); // "transfer" will return an error based on the result of the action.
    }

    function withdrawSend(address payable _to) public {
        bool isSent = _to.send(10); // "send" will return boolean based on the result of the action.
        require(isSent, "Sending of funds unsuccessful.");
    }
}

contract ReceiverNoAction {
    function balance() public view returns(uint) {
        return address(this).balance;
    }

    receive() external payable {}
}

contract ReceiverAction {
    uint public balanceReceived;

    receive() external payable {
        balanceReceived += msg.value;
    }

    function balance() public view returns(uint) {
        return address(this).balance;
    }
}