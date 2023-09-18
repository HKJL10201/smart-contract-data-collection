// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.5.0;

contract Lottery {
    struct Ticket {
        uint256 id;
        uint256 dateTime;
        address payable member;
        bool isWin;
    }

    address payable public admin;
    mapping(uint256 => Ticket) public tickets;
    uint256 ticketPrice = 100;
    uint256 ticketCode;
    uint256 totalTickets;
    uint256 invested;
    uint256 public startDate;
    uint16 public dayCount;
    bool lotterIsDone;

    event BuyTicket(address indexed addr, uint256 amount, uint256 ticketCode);
    event Winner(address indexed winner, uint256 amount, uint256 ticketCode);

    constructor(uint16 _dayCount) public {
        dayCount = _dayCount;
        startDate = block.timestamp;
        admin = msg.sender;
    }

    function buyTicket() public payable returns (uint256) {
        require(msg.value == ticketPrice);
        require(block.timestamp < startDate + (dayCount * 84600));
        admin.transfer(msg.value / 10);
        ticketCode++;
        invested += (msg.value * 90) / 100;

        tickets[ticketCode] = Ticket(
            ticketCode,
            block.timestamp,
            msg.sender,
            false
        );
        emit BuyTicket(msg.sender, msg.value, ticketCode);
        return ticketCode;
    }



    function random(uint count) private view returns(uint){
      uint randomNumber= uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty)))%count;
      return randomNumber;
    }

}
