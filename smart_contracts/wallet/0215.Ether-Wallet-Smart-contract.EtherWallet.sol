//SPDX-License-Identifier:MIT
// Contract created by Mohammed Rizwan

pragma solidity >=0.5.0 < 0.9.0;

contract EtherWallet{
    address payable public owner;

    constructor(){
        owner = payable (msg.sender);
    }

    receive() external payable {}

    function withdraw(uint _amount) external {
        require(msg.sender == owner, "Only the owner can call this method");
        payable(msg.sender).transfer(_amount);                 
    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }
}