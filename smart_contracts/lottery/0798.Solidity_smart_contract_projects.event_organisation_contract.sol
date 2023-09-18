// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract eventcontract{
    struct Event{
        address organizer;
        string name;
        uint date;
        uint price;
        uint ticketcount;
        uint ticketremain;
    }

    mapping(uint=>Event) public events;
    mapping(address=>mapping(uint=>uint)) public tickets;

    uint public nextId;

    function createEvent(string memory name, uint date, uint price, uint ticketcount) external{
        require(date>block.timestamp,"you can organize for future");
        require(ticketcount>0,"create more tickets for organix=zing the event");

        events[nextId] = Event(msg.sender, name, date, price, ticketcount, ticketcount);
        nextId++;
    }

    function buyticket(uint id, uint quantity) external payable{
        require(events[id].date!=0,"event doesnot exist");
        require(events[id].date>block.timestamp,"event has occured");
        Event storage _event = events[id];
        require(msg.value==(_event.price**quantity),"ether is not enough");
        require(_event.ticketremain>=quantity,"not enough ticket");
        
        _event.ticketremain-=quantity;
        tickets[msg.sender][id]+=quantity;
}

    function transferticket(uint id, uint quantity, address to) external{
         require(events[id].date!=0,"event doesnot exist");
        require(events[id].date>block.timestamp,"event has occured");
        require(tickets[msg.sender][id]>=quantity,"no enough tickets");

        tickets[msg.sender][id]-=quantity;
        tickets[to][id]+=quantity;

    }

}