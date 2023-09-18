// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract Sender{
     receive() external payable{}

     function withdrawTransfer(address payable _to) public{
         _to.transfer(10); // It will transfer 10 wei to the above account.
     }

     function withdrawSend(address payable _to) public {
         bool isSent = _to.send(10); // It will send 10 wei to the above account.
         // It is better to use .send
         require(isSent, "Sending the funds was unsuccessful");
     }
}


contract ReceiverNoAction{
    function balance() public view returns(uint){
        return address(this).balance;
    }

    receive() external payable {}
}


contract ReceiverAction {
    uint public balanceReceived;

    receive() external payable {
        balanceReceived += msg.value;
    }

    function balance() public view returns (uint){
        return address(this).balance;
    }
}