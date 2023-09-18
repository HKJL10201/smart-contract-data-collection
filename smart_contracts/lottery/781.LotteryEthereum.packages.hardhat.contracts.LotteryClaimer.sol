pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import 'hardhat/console.sol';
import './LotteryDrawer.sol';

contract LotteryClaimer is LotteryDrawer {
  using SafeMath for uint256;

  struct TicketWithInfo {
    uint8[5] numbers;
    uint256 drawNumber;
    bool claimed;
    TicketStatus ticketStatus;
    uint256 rewardsAmount;
    uint256 id;
  }

  constructor(address _LTY) LotteryDrawer(_LTY) {}

  function claim() public payable returns (uint256) {
    uint256 claimableAmount = 0;
    // Ticket[] memory _tickets = tickets;
    uint256[] memory claimableTicketsOfOwner = ownerToClaimableTickets[msg.sender];
    for (uint256 i = 0; i < claimableTicketsOfOwner.length; i++) {
      Ticket memory _ticket = tickets[claimableTicketsOfOwner[i]];
      // if (_ticket.claimed == false && ticketToOwner[i] == msg.sender) {
      // tickets[i].claimed = true;
      Draw memory draw = draws[_ticket.drawNumber];
      uint256 commonNumbers = compareTwoUintArray(draw.numbers, _ticket.numbers);
      claimableAmount = claimableAmount.add(draw.rewardsByWinningNumber[commonNumbers]);
      // }
    }
    TransferHelper.safeTransfer(LTY, msg.sender, claimableAmount);
    ownerToClaimableTickets[msg.sender] = new uint256[](0);
    claimableBalance = claimableBalance.sub(claimableAmount);
    // (bool sent, ) = msg.sender.call{value: claimableAmount}('');
    // require(sent, 'Failed to send Ether');
    return claimableAmount;
  }

  // Getters
  function getClaimableAmountOfAddress(address _address) external view returns (uint256) {
    uint256 claimableAmount = 0;
    uint256[] memory claimableTicketsOfOwner = ownerToClaimableTickets[_address];
    for (uint256 i = 0; i < claimableTicketsOfOwner.length; i++) {
      Ticket memory _ticket = tickets[claimableTicketsOfOwner[i]];
      if (ticketToOwner[claimableTicketsOfOwner[i]] == _address) {
        uint256 commonNumbers = compareTwoUintArray(draws[_ticket.drawNumber].numbers, _ticket.numbers);
        claimableAmount = claimableAmount.add(draws[_ticket.drawNumber].rewardsByWinningNumber[commonNumbers]);
      }
    }
    return claimableAmount;
  }

  function getClaimableAmountOfTicket(uint256 _ticketId) public view returns (uint256) {
    uint256 claimableAmount = 0;

    // if (tickets[_ticketId].claimed == false) {
    uint256 commonNumbers = compareTwoUintArray(draws[tickets[_ticketId].drawNumber].numbers, tickets[_ticketId].numbers);
    claimableAmount = draws[tickets[_ticketId].drawNumber].rewardsByWinningNumber[commonNumbers];
    // }

    return claimableAmount;
  }

  function getTicketWithRewardsAndStatus(uint256 _ticketId)
    public
    view
    returns (
      uint8[5] memory,
      uint256,
      bool,
      TicketStatus,
      uint256
    )
  {
    Ticket memory ticket = tickets[_ticketId];
    TicketStatus status = TicketStatus.Pending;
    uint256 claimableAmount = 0;
    if (draws[tickets[_ticketId].drawNumber].completed) {
      uint256 commonNumbers = compareTwoUintArray(draws[tickets[_ticketId].drawNumber].numbers, tickets[_ticketId].numbers);
      status = commonNumbers == 2 ? TicketStatus.TwoWinningNumber : commonNumbers == 3 ? TicketStatus.ThreeWinningNumber : commonNumbers == 4
        ? TicketStatus.FourWinningNumber
        : TicketStatus.Lost;
      claimableAmount = commonNumbers > 1 ? draws[tickets[_ticketId].drawNumber].rewardsByWinningNumber[commonNumbers] : 0;
    }

    return (ticket.numbers, ticket.drawNumber, isTicketClaimed(_ticketId), status, claimableAmount);
  }

  function _getTicketsOfOwnerForDraw(address _owner, uint256 _drawId) external view returns (TicketWithInfo[] memory) {
    uint256 ownerTicketCountForDraw = _getOwnerTicketCountForDraw(_owner, _drawId);
    TicketWithInfo[] memory result = new TicketWithInfo[](ownerTicketCountForDraw);
    uint256 counter = 0;
    // drawToTickets[_drawId] returns all the ticket ids of the draw
    // So : Foreach ticket in this draw (where drawToTickets[_drawId][i] is a ticket id)
    for (uint256 i = 0; i < drawToTickets[_drawId].length; i++) {
      // Create currentTicketId var for a better readability
      uint256 currentTicketId = drawToTickets[_drawId][i];
      // If the owner of currentTicketId is the owner we're looking for, add it in result array
      if (ticketToOwner[currentTicketId] == _owner) {
        (uint8[5] memory numbers, uint256 drawNumber, bool claimed, TicketStatus status, uint256 rewardsAmount) = getTicketWithRewardsAndStatus(
          currentTicketId
        );
        result[counter] = TicketWithInfo(numbers, drawNumber, claimed, status, rewardsAmount, i);
        counter = counter.add(1);
      }
    }
    return result;
  }

  function _getCurrentDrawTicketsOfOwner(address _owner) external view returns (TicketWithInfo[] memory) {
    uint256 ownerTicketCountForDraw = _getOwnerTicketCountForDraw(_owner, lotteryCount);

    TicketWithInfo[] memory ticketsOfOwner = new TicketWithInfo[](ownerTicketCountForDraw);
    uint256 counter = 0;

    for (uint256 i = 0; i < drawToTickets[lotteryCount].length; i++) {
      if (_owner == ticketToOwner[drawToTickets[lotteryCount][i]]) {
        (uint8[5] memory numbers, uint256 drawNumber, bool claimed, TicketStatus status, uint256 rewardsAmount) = getTicketWithRewardsAndStatus(
          drawToTickets[lotteryCount][i]
        );
        ticketsOfOwner[counter] = TicketWithInfo(numbers, drawNumber, claimed, status, rewardsAmount, i);
        counter = counter.add(1);
      }
    }

    return ticketsOfOwner;
  }

  function _getOwnerTicketCountForDraw(address _owner, uint256 _drawId) internal view returns (uint256) {
    uint256 ownerTicketCountForDraw = 0;
    for (uint256 i = 0; i < drawToTickets[_drawId].length; i++) {
      if (ticketToOwner[drawToTickets[_drawId][i]] == _owner) {
        ownerTicketCountForDraw = ownerTicketCountForDraw.add(1);
      }
    }
    return ownerTicketCountForDraw;
  }
}
