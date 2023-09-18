// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

// Import this file to use console.log
import "hardhat/console.sol";

uint constant numberOfNumbers = 5;

contract LotteryPhase1 {

    struct NumberOfTicketsInWallet {
      address owner;
      uint256 numberOfTickets;
    }
    

    uint256 public drawTime;
    uint256 public N; // number range.
    address public owner;
    uint256 public ticketPrice;
    // ticket map in public is not fair for former buyer
    mapping(uint256=>NumberOfTicketsInWallet[]) public ticketMap;
    uint256 public totalAmount;

    // N is max num that users can choose.
    constructor(uint256 _drawTime, uint8 _N, uint256 _ticketPrice){
        drawTime = _drawTime;
        N = _N;
        ticketPrice = _ticketPrice;
        owner = msg.sender;
    }

    function buyticket(uint256 ticketNumber, uint256 numberOfTicketToBuy) external payable{
        require(block.timestamp < drawTime, "This Lottery is Over");
        require(msg.value == ticketNumber * ticketPrice, "Price does not match");

        // TODO, handle replicated sender.
        NumberOfTicketsInWallet memory currentRequest;
        currentRequest.owner = msg.sender;
        currentRequest.numberOfTickets = numberOfTicketToBuy;

        ticketMap[ticketNumber].push(currentRequest);
        totalAmount += msg.value;
    }

    function draw() external{
        // TODO, every body should be able to call draw, not only owner.
        // for now, only owner could call for test. 
        require(msg.sender == owner, "Temporal requirement, You are not owner!");
        require(block.timestamp > drawTime, "Not Finished Yet.");

        uint256 winner = rand();

        NumberOfTicketsInWallet[] memory winnerBuyers = ticketMap[winner];

        if(winnerBuyers.length == 0){
            // No winner this time.
            return;
        }

        uint numWinnerTickets = 0;
        for(uint i = 0; i < winnerBuyers.length; ++i){
            numWinnerTickets += winnerBuyers[i].numberOfTickets;
        }
        for(uint i = 0; i < winnerBuyers.length; ++i){
           address payable winnerAddress = payable(winnerBuyers[i].owner); 
           winnerAddress.transfer(totalAmount/winnerBuyers[i].numberOfTickets);
        }

    }

// TODO, change pseudo random to oracle random.
    function rand() public view returns(uint256)
{
    uint256 seed = uint256(keccak256(abi.encodePacked(
        block.timestamp + block.difficulty +
        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
        block.gaslimit + 
        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
        block.number
    )));

    return (seed - ((seed / (N**numberOfNumbers)) * (N**numberOfNumbers)));
}
}
