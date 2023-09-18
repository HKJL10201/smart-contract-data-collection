// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CompteEpargne is Ownable {

    uint firstDepositDate;
    uint nbDeposit;
    mapping(uint => uint) public deposits;


    constructor (){
        nbDeposit = 0;
        firstDepositDate = 0;
    }

    function deposit() external payable {
        deposits[nbDeposit] += msg.value;
        if (nbDeposit == 0){
            firstDepositDate = block.timestamp;
        }
        nbDeposit += 1;
    }

    function retrieve() external payable onlyOwner{
        require(block.timestamp >= firstDepositDate+ 1 minutes,"Wait 1 minute after the first deposit to withdraw");
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}
