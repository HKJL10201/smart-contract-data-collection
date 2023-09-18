// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Lottery.sol";

contract Factory {

    // Try contract
    Lottery public lottery;
    // Interface to comunicate with nftKitty contract
    IKitty iKitty;
    // Address of nft contract
    address kittyNFT;
    // Owner
    address owner;

    event LotteryCreated();

    constructor(){
        owner = msg.sender;
    }

    // Instantiate a new Lottery contract using two param. M and K, and emit the event
    // M is used to represent the number of round 
    // K is used to represent the randomness
    function newLottery(uint K, uint duration, uint price) public {
        require(msg.sender == owner, "Only the owner can create a new lottery");
        lottery = new Lottery(K, duration, price, kittyNFT, owner);
        iKitty.setLotteryAddress(address(lottery));
        emit LotteryCreated();
    }

    //Return the address of the instantiated contract 
    function getAddr() public view returns(Lottery){
        return lottery;
    }

    //Associate the address of the KittyNFT contract using the parameter addr
    function setKittyAddr(address addr) public {
        require(msg.sender == owner, "Only the owner can set the address");
        iKitty = IKitty(addr);
        kittyNFT = addr;
    }

    //Tell to KittyNFT which is the active Lottery contract address
    function setLotteryAddr(address _lottery) public {
        require(msg.sender == owner, "Only the owner can set the address");
        iKitty.setLotteryAddress(_lottery);
    }

}