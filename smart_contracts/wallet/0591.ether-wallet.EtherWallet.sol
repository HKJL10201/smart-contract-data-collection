// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EtherWallet {
    address payable public owner;
    event Log (address sender, uint amount);

// initiliaze owner state variable
    constructor()payable{
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require (msg.sender == owner, "Not Wallet Owner");
        _;
    }
    // receive ether
    receive() external payable{
        emit Log(msg.sender, msg.value);
    }
    // send ether to owner
    function withdraw (uint _amount) external onlyOwner{
        require (_amount <= address(this).balance, "Not enough funds to withdraw" );
        (bool success,) = owner.call{value: _amount}("");
        require (success, "Failed to send funds");
        emit Log(msg.sender, _amount);

    }
    // check balance
    function walletBalance() external view returns (uint balance) {
        balance = address(this).balance;
    }
    // revert if called with no existing function   
    fallback() external payable{
        revert("invalid contract function");
    }
}
