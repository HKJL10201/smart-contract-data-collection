// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract OnePersonWallet {

    address payable public immutable owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }


    function withdraw(uint _amount) external onlyOwner {
    
        //replacing owner with payable(msg.sender) to use a memory variable instead of a state variable to save some gas (we already know the caller is the owner)
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        require(success, "Failed to send the transaction");
    } 

    //receive could be replaced with a fallback. The reason why i use receive is to make sure that the intention of this contract are more clear.
    //This contract should only receive ether and not work with data.
    receive() external payable {
    }
}
