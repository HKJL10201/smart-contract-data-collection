pragma solidity ^0.4.19;

/**
 * The LotteryLib
 */

library LotteryLib {
  
  struct Lottery {
    byte[6] ticket;
  }
  
  function populate(Lottery storage lottery, byte[6] data) {
    for (uint i = 0; i < 6; i++) {
      require(validated(data[i]));
      lottery.ticket[i] = data[i];
    }
  }

  function hash(Lottery storage lottery) returns(bytes32) {
    return sha3(lottery.ticket);
  }

  function getNumNotMatching(Lottery storage lottery, byte[6] result) returns(uint) {
    uint numNotMatching = 0;
    for (uint i = 0; i < 6; i++) {
      if (lottery.ticket[i] != result[i]) {
        numNotMatching++;
      }
    }
    return numNotMatching;
  }
  
  function validated(byte data) returns (bool) {
    return (data <= 0x0c && data != 0x00);
  }

}
