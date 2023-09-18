pragma solidity ^0.4.19;

import './LotteryLib.sol';

/**
 * The LotteryStorageLib
 */
library LotteryStorageLib {
  using LotteryLib for LotteryLib.Lottery;

  struct LotteryStorage {
    /** ticket to list of users who bought this ticket. array might contain
      * duplicate addresses */
    mapping(bytes32 => address[]) ticketToUsers;
    /** all ticket entries to the lottery */
    LotteryLib.Lottery[] lotteries;
  }

  function enterLottery(LotteryStorage storage store, LotteryLib.Lottery storage lottery, byte[6] lotteryTicket, address player) internal {
    lottery.populate(lotteryTicket);
    bytes32 lotteryHash = lottery.hash();
    if (store.ticketToUsers[lotteryHash].length == 0) {
      store.lotteries.push(lottery);
    }
    store.ticketToUsers[lotteryHash].push(player);
  }

  function enterLottery(LotteryStorage storage store, LotteryLib.Lottery storage lottery, bytes lotteryTicket, address player) internal {
    require(lotteryTicket.length >= 6);
    byte[6] lotteryTicketBytes;
    for (uint i = 0; i < 6; i++) {
      lotteryTicketBytes[i] = lotteryTicket[i];
    }
    enterLottery(store, lottery, lotteryTicketBytes, player);
  }

  function numLotteries(LotteryStorage storage store) internal returns(uint) {
    return store.lotteries.length;
  }

  function getLottery(LotteryStorage storage store, uint i) internal view returns(LotteryLib.Lottery) {
    return store.lotteries[i];
  }

  function getWinners(LotteryStorage storage store, LotteryLib.Lottery storage lottery) internal returns(address[]) {
    return store.ticketToUsers[lottery.hash()];
  }

  /** functions to read what's stored */
  function getLotteries(LotteryStorage storage store) returns(LotteryLib.Lottery[]) {
    return store.lotteries;
  }
  
  function getPlayerAddressForLottery(LotteryStorage storage store, bytes32 hash) returns(address[]) {
    return store.ticketToUsers[hash];
  }

}
