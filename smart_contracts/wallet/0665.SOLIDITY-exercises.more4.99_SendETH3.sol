//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

/*
INSTRUCTIONS: Deploy SampleContract and AnyConctract. Then open SampleContract, 
click on owner to see your account and click on getBalance to see your balance. 
Your balance should be "0". Then click on the msg.value input area, enter "1", choose "ether"
option. Then go down, you will see "transact" button. click on the button without inserting anything.
Now check the balance and it should a big number. Then copy the account of AnyContract. And then go to "sendEth"
function input area, enter _amount and then account of AnyContract. Then click on the button and it should work.
You can check your balance to see if it really worked." 
*/
contract SampleContract {
    /* the contract structure down is the same for many contracts.
    owner is set to deployer(aka msg.sender) 
    anybody can send ether to the contract but only owner can send ether out of this contract
    - create owner address, make it payable and set it to msg.sender by using constructor
    - declare receive() method to make sure anybody can send ether to the contract
    - create a function that will allow owner to send ether to anywhere he/she wants
    - also create a view function to check contract balance*/
     
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }
    receive() external payable {}

    /*
    function sendEth(uint _amount) external {
        require(msg.sender == owner, "you are not the owner");
        payable(msg.sender).transfer(_amount);
    }
    */

    function sendEth(uint _amount, address payable _to) external {
        require(msg.sender == owner, "you are not the owner");
        (bool mySuccess, ) = _to.call {value: _amount}("");
        require(mySuccess, "failed: Maybe there isnt enough money");
    }


    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

     
}

contract AnyContract {
    fallback() external payable{}
}
