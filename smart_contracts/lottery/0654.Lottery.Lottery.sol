pragma solidity ^0.4.23;

contract Lottery {
    uint public allTickets;
    uint public soldTickets;
    string[] public buyers;

    function Lottery() {
        allTickets = 5;
        soldTickets = 0;
    }

    function getAllTickets() returns (uint allTicketsForSale) {
        return allTickets;
    }

    function getSoldTickets() returns (uint currentTicketsSold) {
        return soldTickets;
    }

    function randomGen() constant returns (uint randomNumber) {
        return(uint(sha3(block.blockhash(block.number-1), block.timestamp))%soldTickets.length);
    }

    function buyTicket(string ticketBuyer) returns (string buyer) {
        if (soldTickets < allTickets) {
            soldTickets++;
            buyers.push(ticketBuyer);
            string result = buyers[soldTickets-1];
            return result;
        }
        return;
    }

    function generateWinner() returns (string winner) {
        if (buyers.length > 0) {
            uint randomNumber = randomGen();
            return buyers[randomNumber];
        }
        else return;
    }
}
