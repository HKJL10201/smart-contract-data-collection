pragma solidity 0.5.10;

import "./Owner.sol";

contract Lottery is Owner {
  uint internal nTickets = 0;     // number of tickets
  uint internal ticket_price = 0; // ticket pice
  uint internal prize = 0;        // winner prize
  uint internal counter = 0;      // current ticket
  uint internal aTickets = 0;     // number of available tickets
  bool internal finished = true;

  mapping (uint => address) internal players;     // players map
  mapping (address => bool) internal addresses;   // player address

  // Event that is called when the winner is found.
  event winner(uint indexed counter, address winner, string message);

  // Return the current game status
  function status() public view returns(uint, uint, uint, uint) {
    return (nTickets, aTickets, ticket_price, prize);
  }

  // Lottery constructor, initialize the contract
  constructor(uint tickets, uint price) public payable onlyOwner {
    if (tickets <= 1 || price == 0 || msg.value < price) {
      revert();
    }

    nTickets = tickets;
    ticket_price = price;
    aTickets = nTickets - 1;
    players[++counter] = owner;
    prize = prize + msg.value;
    addresses[owner] = true;
    finished = false;
  }

  // Function to buy a ticket
  function play() public payable {
    if (addresses[msg.sender] || msg.value < ticket_price || aTickets == 0) {
      revert();
    }

    aTickets = aTickets - 1;
    players[++counter] = msg.sender;
    prize = prize + msg.value;
    addresses[msg.sender] = true;
    if (aTickets == 0 && !finished) {
      end();
    }
  }

  // End the contract and to find a winner
  function end() internal {
      if (!finished) {
        raffle();
      }
      finished = true;
      prize = 0;
      nTickets = 0;
      aTickets = 0;
      ticket_price = 0;
      counter = 0;
  }
  
  function random() private view returns (uint){
      return uint(keccak256(abi.encodePacked(block.difficulty, now)));
  }

  // Generate the winner and transfer the prize to his address
  function raffle() internal {
    uint index = random() % nTickets;
    address payable winnerAddr = address(uint160(players[index]));
    emit winner(index, winnerAddr, "The raffle found its winner!!");
    winnerAddr.transfer(prize);
  }
}
