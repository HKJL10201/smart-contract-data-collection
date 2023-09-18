// SPDX-License-Identifier: MIT

/*DEPLOY INSTRUCTIONS: Deploy payable4 and payable5. Then copy the address of payable5 
and go to payable4 functions input area and paste it then go to msg.value area and insert 
any value and click on the function. You can then check if transfer is made by calling 
balance function inside payable5
*/
pragma solidity >=0.8.7;

contract Payable4 {
    /*
    transfer -- 2300 gas, reverts if transaction fails
    send -- 2300 gas, returns bool(true or false)
    call -- forwards all gas, returns bool and data

    transfer and send is not used much because of their fixed gas cost. USE CALL everytime.
    
    PAYABLE address : can send eth
    PAYABLE function: can receive eth
    TRANSFER function: can send eth

    To make a contract that it can send it we must make it "payable" first. We can do it by declaring
    contructor function as payable.   
    OR you can can create a payable fallback function. 
    OR you can can create a payable receive function.  
     */



    receive()external payable{}
    //receive() external payable{}

    //this function will transfer ether from function account to 
    // the address specified in parameter
    function optionTransfer(address payable _to) external payable {
        _to.transfer(123); 
    }

    //send function is hardly used
    function optionSend(address payable _to) external payable {
        bool sent = _to.send(123);
        require(sent, "send failed");
    }

    //This is most used. "bytes memory data" is optional. We can take it out.
    // "_to.call{value: 1 ether}("")" returns a bool and a bytes.
    // bool will be true if transaction is successful, if not false
    // bytes will include some data and I dont know for now what it is.
    function optionCall(address payable _to) external payable {
        (bool mySuccess, ) = _to.call{value: 123}("");
        require(mySuccess, "failed to send Ether");
    }

    //in place of 123, you can put "msg.value"

}

contract Payable5{

    event transferLog( uint amount, uint gas);

    receive() external payable {
        emit transferLog(msg.value, gasleft());
    }

    function getBalances2() external view returns(uint) {
        return address(this).balance;
    }


/*now contract is finished and it is a piece of art. 
The contract first creates a mapping, then it adds to mapping with order number. Then just by 
entering order number, I can send the amount to the relevant account represented by order number"
last function checks the amount of ether in each contract by entering contract order number in mapping
*/
}



contract Payable6{

    receive()  external payable {}

    mapping(uint => address payable) public accounts;

    function addToMapping(uint _myOrder, address payable _myAddress) external {
        accounts[_myOrder] = _myAddress;
    }

    function makeTransaction(uint _accountOrder) external payable {
        address payable _to = accounts[_accountOrder];
        (bool sent,) = _to.call{value: msg.value}("");
        require(sent, "failed to send Ether");
    }

    function getBalances(uint _accountOrder) external view returns(uint) {
        address queryAddress = accounts[_accountOrder];
        return address(queryAddress).balance;
    }


    //now contract is finished and it is a piece of art. 
//The contract first creates a mapping, then it adds to mapping with order number. Then just by 
//entering order number, I can send the amount to the relevant account represented by order number"
// last function checks the amount of ether in each contract by entering contract order number in mapping
}

