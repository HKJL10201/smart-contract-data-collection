pragma solidity ^0.4.19;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';

/**
 * The PayoutLib
 */
library PayoutBacklogLib {
  using SafeMath for uint256;

  struct Payout {
    uint amount;
    uint period;
    uint index;  // index in backlog's winners array
  }

  struct PayoutBacklog {
    mapping(address => Payout) backlog;
    address[] winners;
  }
  
  event LogPayWinner(address winner, uint amount);
  event LogDeleteWinner(address winner);

  function addPrizeToWinner(PayoutBacklog storage payoutBacklog, address winner, uint amount, uint period) {
    Payout payout = payoutBacklog.backlog[winner];
    if (payout.period == 0) {
      payout.period = period;
      payout.index = payoutBacklog.winners.length;
      payoutBacklog.winners.push(winner);
    } else if (period > payout.period) {
      payout.period = period;
    }
    payout.amount = payout.amount.add(amount);
    payoutBacklog.backlog[winner] = payout;
  }
  
  /** Payout everyone in the backlog that has prizes over the threshold */
  function pay(PayoutBacklog storage payoutBacklog, uint threshold) {
    for (uint i = 0; i < payoutBacklog.winners.length; i++) {
      address winner = payoutBacklog.winners[i];
      Payout payout = payoutBacklog.backlog[winner];
      uint payoutAmount = payout.amount.div(payout.period);

      if (payoutAmount >= threshold) {
        LogPayWinner(winner, payoutAmount);
        winner.transfer(payoutAmount);
        payout.period = payout.period.sub(1);
        payout.amount = payout.amount.sub(payoutAmount);

        if (payout.period == 0) {
          deleteWinner(payoutBacklog, payout, winner);
        }
      }
    }
  }

  /** Delete winner address from backlog once all his prizes are paid out */
  function deleteWinner(PayoutBacklog storage payoutBacklog, Payout payout, address winner) internal {
    LogDeleteWinner(winner);
    payoutBacklog.winners[payout.index] = payoutBacklog.winners[payoutBacklog.winners.length-1];
    payoutBacklog.winners.length--;
    delete payoutBacklog.backlog[winner];
  }
  
  /** function to read what's stored */
  function getNumWinners(PayoutBacklog storage payoutBacklog) returns(uint) {
    return payoutBacklog.winners.length;
  }

  function getWinnerAtIndex(PayoutBacklog storage payoutBacklog, uint index) returns(address) {
    return payoutBacklog.winners[index];
  }
  
  
  function getPayoutForWinner(PayoutBacklog storage payoutBacklog, address winner) returns(uint, uint, uint) {
    Payout payout = payoutBacklog.backlog[winner];
    return (payout.amount, payout.period, payout.index);
  }

}
