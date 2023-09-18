// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract WatchNFT {

    event NewWallet(
        address indexed from,
        uint256 timestamp,
        string message
        );

    address owner;
    address public wallet;

    constructor() {
        owner = msg.sender;
    }

    function SetNFTWallet(address _addr) public {
        require(msg.sender == owner, "Only the contract owner can change the address");

        wallet = _addr;

        emit NewWallet(
            msg.sender,
            block.timestamp,
            "Wallet address changed"
        );
    }
    
    function getWallet() public view returns(address) {
      //  require(msg.sender == owner, "Only the contract owner can see the address");
        return wallet;
    } 
}
