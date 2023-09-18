// SPDX-License-Identifier: MIT

struct Lottery {
  uint startTime;
  uint lastDraw;

  uint totalPot;

  bytes32 winningTicket;
  bool finished;
}

pragma solidity ^0.8.2;

import "../Utils/RevenueStream.sol";
import "../Utils/UtilityPackage.sol";

contract BaseLottery is UtilityPackage {

  string public name;

  uint public frequency;
  uint public price;
  uint public odds;

  uint public currentLotto = 0;
  uint public currentDraw = 0;
  uint public ticketCounter = 0;

  uint public totalValuePlayed = 0;

  struct Ticket {
    address[] owners;
    uint ticketNumber;
  }

	mapping (uint => Lottery) lottos;
  mapping (bytes32 => Ticket) public tickets;
  mapping (uint => mapping(address => bytes32[])) public userTickets;
  mapping (address => uint) public debtToUser;

  event newRound(uint lottoNumber);
  event newEntry(address entrant, bytes32 ticketID, uint totalPot);
  event newDraw(bool winnerSelected, bytes32 winningTicket);
  event newPayment(address user, uint amount);

  function startNewRound() internal returns (bool) {
    currentLotto++;
    lottos[currentLotto] = Lottery(_timestamp(), _timestamp(), 0, bytes32(0), false);
    emit newRound(currentLotto);
    return true;
  }

  function resetGame() internal returns (bool) {
    currentDraw = 0;
    ticketCounter = 0;
    startNewRound();
    return true;
  }

  function selectWinningTicket() internal view returns (bytes32) {
    uint winningNumber = generateTicketNumber();
    bytes32 winningID = generateTicketID(winningNumber);

    if (tickets[winningID].owners.length > 0) {
      return winningID;
    } else {
      return bytes32(0);
    }
  }

  function createNewTicket() internal returns (bytes32) {
    uint ticketNumber = generateTicketNumber();
    bytes32 _ticketID = generateTicketID(ticketNumber);

    if (tickets[_ticketID].owners.length > 0) {
      tickets[_ticketID].owners.push(_sender());
      return _ticketID;
    } else {
      address[] memory newOwner = new address[](1);
      newOwner[0] = _sender();
      tickets[_ticketID] = Ticket(newOwner, ticketNumber);
      return _ticketID;
    }
  }

  function finalAccounting() internal returns (bool) {
    lottos[currentLotto].finished = true;
    assert(safeUserDebtCalculation());
    return true;
  }

  function safeUserDebtCalculation() internal returns (bool) {
    bytes32 winningTicket = lottos[currentLotto].winningTicket;
    uint winnings = lottos[currentLotto].totalPot;

    uint winnerCount = tickets[winningTicket].owners.length;
    uint winningsPerUser = (winnings / winnerCount);

    address[] memory winners = tickets[winningTicket].owners;

    for (uint i = 0; i < winners.length; i++) {
      debtToUser[winners[i]] += winningsPerUser;
    }
    return true;
  }

  function _safePay() internal returns (uint) {
    uint _winnings = debtToUser[_sender()];
    debtToUser[_sender()] = 0;
    return _winnings;
  }

  function _enter(uint _toPot) internal returns (bool) {
    ticketCounter++;
    totalValuePlayed += price;
    lottos[currentLotto].totalPot += _toPot;
    bytes32 ticketID = createNewTicket();
    userTickets[currentLotto][_sender()].push(ticketID);

    emit newEntry(_sender(), ticketID, lottos[currentLotto].totalPot);
    return true;
  }

  function _draw() internal returns (bool) {
    bytes32 _winner = selectWinningTicket();

    if (_winner == bytes32(0)) {
      currentDraw++;
      emit newDraw(false, _winner);
      return false;
    } else {
      lottos[currentLotto].winningTicket = _winner;
      finalAccounting();
      resetGame();
      emit newDraw(true, _winner);
      return true;
    }
  }

  function generateTicketNumber() internal view returns (uint) {
    uint _rando = generateRandomNumber();
    uint _ticketNumber = _rando % odds;
    return _ticketNumber;
  }

  function generateTicketID(uint _ticketNumber) internal view returns (bytes32) {
    bytes32 _ticketID = keccak256(abi.encodePacked(currentLotto, currentDraw, _ticketNumber));
    return _ticketID;
  }

  function generateRandomNumber() internal view returns (uint) {
    return (uint(keccak256(abi.encodePacked(block.timestamp, block.number, ticketCounter))));
  }
}
