//SPDX-Licence-Identifier: MIT
pragma solidity >=0.8.7;

contract Payable2 {
    mapping(address => uint) accounts;

    function investEthToThisContract() external payable{
        if(msg.value < 1 ether) {
            revert();
        } 
        accounts[msg.sender] = msg.value;
    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    function checkTransaction() external view returns(uint) {
        return accounts[msg.sender];
    }
}