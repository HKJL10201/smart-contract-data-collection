//one organizer can have multiple events under her name, then there can be many 
//organizers. Hence this is a case of mapping inside a mapping to store 
//uint(like index while storing) --> struct(event type) and another one to store 
//address(of the organizer) --> mapping#1.

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 < 0.9.0;

contract EventOrganization {
    struct Event{
        address organizer;
        string name; //name of event
        uint date;
        uint priceOfTicket;
        uint ticketCount;
        uint ticketRemaining; // remaining is equal to initial count 
    }

    mapping(uint=>Event) public events; //mapping from index numbers to information
    //of the event
    mapping(address=>mapping(uint=>uint)) public tickets; //mapping from all the
    //attendees to their respective events

    uint public nextId;

    function createEvent(string memory name, uint date, uint price, uint ticketCount) external { //no ticketsRemaining because it is same as ticketCount in the beginning
        require(date>block.timestamp, "You can only organise an event for a future date.");
        require(ticketCount>0, "You must create at least 1 ticket.");

        events[nextId] = Event(msg.sender, name, date, price, ticketCount, ticketCount);
        nextId++;
    }

    function buyTicket(uint id, uint quantity) external payable { //id is the show id, indicating which event
        require(events[id].date!=0, "No such event is available"); //if an incorrect id is added then as 'date' is uint, it would be 0
        require(events[id].date>block.timestamp, "The event has already taken place"); // will check that the date of id's event is in future
        Event storage _event = events[id];
        require(msg.value==(_event.priceOfTicket*quantity), "amount is either less than total amount to be paid or is greater than that.");
        require(_event.ticketRemaining>=quantity, "Enough tickets are not available");
        _event.ticketRemaining -= quantity; 
        tickets[msg.sender][id] += quantity;
    }

    function transferTicket(uint id, uint quantity, address to) external {
        require(tickets[msg.sender][id]>=quantity,"you don't have enough ticketss to transfer");
        require(events[id].date!=0, "No such event is available");
        require(events[id].date>block.timestamp, "The event has already taken place");
        tickets[msg.sender][id] -= quantity;
        tickets[to][id] += quantity;
    }
}
