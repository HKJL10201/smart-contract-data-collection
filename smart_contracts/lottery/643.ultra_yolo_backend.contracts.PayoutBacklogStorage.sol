pragma solidity ^0.4.19;

import './PayoutBacklogLib.sol';

import 'zeppelin-solidity/contracts/lifecycle/TokenDestructible.sol';

/**
 * The PayoutBacklogStorage contract
 * Store backlog to ensure every winner gets paid. And info never gets lost
 */
contract PayoutBacklogStorage is TokenDestructible {
  using PayoutBacklogLib for PayoutBacklogLib.PayoutBacklog;

  PayoutBacklogLib.PayoutBacklog payoutBacklog;

  event LogAddPrizeWinnerToBacklog(address winner, uint amount, uint period);

  function addPrizeToWinner(address winner, uint amount, uint period) onlyOwner {
    LogAddPrizeWinnerToBacklog(winner, amount, period);
    payoutBacklog.addPrizeToWinner(winner, amount, period);
  }
  
  /** Payout everyone in the backlog that has prizes over the threshold */
  function pay(uint threshold) onlyOwner {
    payoutBacklog.pay(threshold);
  }

  function () external payable { }

  /** helper functions to inspect the payout backlog storage */
  function getNumWinners() returns(uint) {
    return payoutBacklog.getNumWinners();
  }
  
  function getWinnerAtIndex(uint index) returns(address) {
    return payoutBacklog.getWinnerAtIndex(index);
  }
  
  function getPayoutForWinner(address winner) returns(uint, uint, uint) {
    return payoutBacklog.getPayoutForWinner(winner);
  }
  
}
