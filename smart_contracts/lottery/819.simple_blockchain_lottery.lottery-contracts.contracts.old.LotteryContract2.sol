// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LotteryContract2 is PullPayment, Ownable {
    uint public lotteryId;
    uint private winningProbability;
    uint public ticketCost;
    mapping (uint => address payable) public lotteryHistory;
    mapping(uint => uint) public lotteryPools;

    event LotteryTicket(
        address indexed buyerAddress,
        address lotteryAddres,
        uint winningPool,
        bool hasWon);

    constructor() {
        lotteryId = 1;
        winningProbability = 500;
        ticketCost = 1e18;
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

    // function getTicketCost() public view returns (uint){
    //     return ticketCost;
    // }

    // function getWinnerByLottery(uint _lotteryId) public view returns (address payable) {
    //     return lotteryHistory[_lotteryId];
    // }

    // function getLotteryPoolbyLottery(uint _lotteryId) public view returns (uint) {
    //     return lotteryPools[_lotteryId];
    // }

    // function getCurrentPool() public view returns (uint) {
    //     return address(this).balance;
    // }


    function enter() public payable  {
        require(msg.value == ticketCost, "Wrong number of ether");
        uint balance = address(this).balance;
        if (getRandomNumber() > winningProbability){
            _asyncTransfer(payable(msg.sender), balance);
            withdrawPayments(payable(msg.sender));

            // Modyfing state after transaction.
            lotteryHistory[lotteryId] = payable(msg.sender);
            lotteryPools[lotteryId] = balance;
            lotteryId++;
            emit LotteryTicket(msg.sender, owner(), balance, true);
        }else{
            emit LotteryTicket(msg.sender, owner(), balance, false);
        }
    }

    function getRandomNumber() public view returns (uint) { //should be private
        return uint(keccak256(abi.encodePacked(owner(), block.timestamp))) % 1000;
    }
}

