// SPDX-License-Identifier: MIT
// Created by Jan Gruszczynski

pragma solidity ^0.8.10;
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LotteryContract4 is PullPayment, Ownable {
    uint public lotteryId;
    uint private winningProbability;
    uint public ticketCost;
    mapping (uint => address payable) public lotteryHistory;
    mapping(uint => uint) public lotteryPools;

    event LotteryTicket(
        address indexed buyerAddress,
        uint winningPool,
        bool hasWon);

    constructor() {
        lotteryId = 0;
        winningProbability = 500;
        ticketCost = 1e18;
    }

    // msg.data is not empty
    fallback() external payable {
        revert("Couldn't decode msg.data");
    }

    // msg.data is empty
    receive() external payable {
        enter();
    }


    function setWinningProbability(uint _winningProbability) onlyOwner public{
        require(_winningProbability > 0 && _winningProbability <= 1000, "Winning probability must be between (0,1000]");
        winningProbability = _winningProbability;
    }

    function getWinningProbability() private view returns (uint){
        return winningProbability;
    }

    function setWinningTicketCost(uint _ticketCost) onlyOwner public{
        require(_ticketCost >= 1e1, "Ticket cost must be greater than 1 wei");
        ticketCost = _ticketCost;
    }

    function getAllPools() public view returns (uint[] memory){
        uint[] memory ret = new uint[](lotteryId);
        for (uint i = 0; i < lotteryId; i++) {
            ret[i] = lotteryPools[i];
        }
        return ret;
    }

    function getAllWinningAddresses() public view returns (address[] memory){
        address[] memory ret = new address[](lotteryId);
        for (uint i = 0; i < lotteryId; i++) {
            ret[i] = lotteryHistory[i];
        }
        return ret;
    }

    function enter() public payable  {
        require(msg.value == ticketCost, "Wrong number of ether");
        uint balance = address(this).balance;
        if (getRandomNumber() > winningProbability){
            _asyncTransfer(payable(msg.sender), balance);
            withdrawPayments(payable(msg.sender));

            // Modifying state after transaction.
            lotteryHistory[lotteryId] = payable(msg.sender);
            lotteryPools[lotteryId] = balance;
            lotteryId++;
            emit LotteryTicket(msg.sender, balance, true);
        }else{
            emit LotteryTicket(msg.sender, balance, false);
        }
    }

    function getRandomNumber() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(owner(), block.timestamp))) % 1000;
    }
}

