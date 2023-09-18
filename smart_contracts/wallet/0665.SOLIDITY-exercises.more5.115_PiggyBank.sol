//SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.7;

contract PiggyBank {
    /*PiggyBank is a contract which is used to let everyone to deposit
    ether into this contract. But only the owner will be able to withdraw 
    it. Withdrawing is only possible by selfdestructing the contract.
    
    To make piggybank contract payable, we add a fallback function. But
    we expect msg.data to be empty everytime. So, we can use "receive", 
    instead of "fallback"
    
    We also create a classic owner modifier (1-2-3 steps) to make sure 
    the one who can kill contract is the owner. He also sends the ethers 
    to his address*/

    event Deposit(uint amount);
    event Withdraw(uint amount, string text);

   /*1*/ address public owner;

    /*2*/constructor() {
            owner = msg.sender;
        }

    /*3*/modifier onlyOwner() {
            require(msg.sender == owner, "not owner");
            _;
        }

    receive() external payable{
        emit Deposit(msg.value);
    }

    /*We should first emit the event, then destroy the contract */

    function withdraw() external onlyOwner{
        emit Withdraw(address(this).balance, "existing ethers transferred and contract destructed.");
        selfdestruct(payable(msg.sender));
    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }
}