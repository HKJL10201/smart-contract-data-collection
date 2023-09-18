//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ticket.sol";

contract LotteryMachine {
    address private owner;
    address private casino;
    uint commission = 1;
    Ticket[] tickets;
    uint come = 0;

    function createStartTickets()  private {
        // tickets.push(new Ticket(address(this), 0.1 ether, 2, commission));
        tickets.push(new Ticket(address(this), 1 ether, 2, commission));
        // tickets.push(new Ticket(address(this), 10 ether, 2, commission));

        // tickets.push(new Ticket(address(this), 0.1 ether, 10, commission));

        // tickets.push(new Ticket(address(this), 1 ether, 100, commission));
        // tickets.push(new Ticket(address(this), 10 ether, 100, commission));

        // tickets.push(new Ticket(address(this), 0.01 ether, 1000, commission));
        // tickets.push(new Ticket(address(this), 1 ether, 1000, commission));
    }

    constructor(address _owner) {
        casino = msg.sender;
        owner = _owner;
        createStartTickets();
    }

    receive() external payable {
        // come += msg.value;

        uint balance = getBalance();
        uint percent = balance / 100;
        uint winSize = percent * commission;
        
        // address(owner).call{value: winSize}("");
        payable(casino).transfer(winSize);
        (bool success,) = address(owner).call{value: getBalance()}("");
        require(success);
    }

    fallback() external payable {
        // payable(owner).transfer(msg.value);
    }
    
    function createTicket(uint _price, uint _limit) public returns(Ticket) {
        require(_limit > 1, "Limit must be from 2 to 255");
        require(_limit < 256, "Limit must be from 2 to 255");
        Ticket ticket = new Ticket(address(this), _price, _limit, commission);
        tickets.push(ticket);
        return ticket;
    }

    function getTickets() public view returns(Ticket[] memory) {
        return tickets;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getOwner() public view returns(address) {
        return owner;
    }

    function getCommision() public view returns(uint) {
        return commission;
    }

    function withdrow() public {
        payable(owner).transfer(getBalance());
    }

}