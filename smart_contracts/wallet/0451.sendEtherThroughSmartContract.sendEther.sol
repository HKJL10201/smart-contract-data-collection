// SPDX-License-Identifier: GIT

pragma solidity ^0.8.17;
// send ether from one address to another "smart contract" 

contract ethTransfer{
// event to capture the transferd status
    event Transferred(address _sender , uint _value , address _reciever);

// struct recipient for recievers address and name
    struct recipient{
        address payable recieversAddress;
        string name;
    }

//  function to sendeth from one address to other
    function sendETH(address recieversAddress , string memory name) payable public returns(bool){
        (bool sent,) = recieversAddress.call{value: msg.value}("");
        emit Transferred(msg.sender ,msg.value ,recieversAddress);
        return sent;
    }

}
