// SPDX-License-Identifier: MIT
pragma solidity ^0.5.1;

contract Ticket {
    uint256 public ticketPrice;
    address public eventOrganizer;
    uint256 public maxTickets;
    uint256 public totalTickets;

    mapping(uint256 => address) public ticketOwners;

    constructor(uint256 _price, uint256 _maxTickets) public {
        ticketPrice = _price;
        maxTickets = _maxTickets;
        eventOrganizer = msg.sender;
        totalTickets = 0;
    }

    function mintTicket() public payable {
        require(totalTickets < maxTickets, "Sold out!");
        require(msg.value == ticketPrice, "Incorrect payment!");
        
        uint256 ticketId = totalTickets + 1;
        ticketOwners[ticketId] = msg.sender;
        totalTickets = ticketId;
    }

    function withdrawFunds() public {
    require(msg.sender == eventOrganizer, "Only the organizer can withdraw funds");
    address payable organizerPayable = address(uint160(eventOrganizer));
    organizerPayable.transfer(address(this).balance);
}

}
