pragma solidity ^0.4.19;

import './oraclizeAPI_0.5.sol';
import './LotteryGame.sol';

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract LotteryResultGenerator is Ownable, usingOraclize {

  /** each number in lottery result will be duodecimal */
  uint constant MODULO = 12;
  /** number of seconds to wait before the execution takes place */
  uint constant DELAY = 0;
  /** number of bytes in each lottery random number digit */
  uint constant N = 1;
  /** amount of gas we want Oraclize to set for the callback function */
  uint constant CALLBACK_GAS = 200000;
  /** number of digits in the lottery result */
  uint constant NUM_LOTTERY_DIGITS = 6;

  /** the collector to notify when results are generated */
  LotteryGame public lotteryGame;
  /** state variable to keep tract of how many digits have been returned by oraclize */
  uint public numDigitsLeft;
  /** mapping between betId to random number index(1-6) in the lottery result
    * 1-based indexing necessary because solidity doesn't have null. The first element
    * would be indistinguishable from none element */
  mapping(bytes32 => uint) public betIdToIndex;
  bytes32[6] public betIds;
  /** lottery result. 6 digits of duodecimal numbers */
  byte[6] public lotteryResult;

  event OraclizeResultByte(byte resultByte);
  event LogLotteryResult(byte[6]);

  modifier onlyOraclize {
    if (msg.sender != oraclize_cbAddress()) throw;
    _;
  }

  modifier onlyIfBetExists(bytes32 betId) { 
    uint index = betIdToIndex[betId];
    require(index >= 1 && index <= 6);
    _;
  }

  function LotteryResultGenerator(address _lotteryGameAddress) {
    oraclize_setProof(proofType_Ledger);
    lotteryGame = LotteryGame(_lotteryGameAddress);
  }

  function () external payable { }

  function generateResult() onlyOwner payable returns(bytes6) {
    numDigitsLeft = 6;
    for (uint i = 0; i < NUM_LOTTERY_DIGITS; i++) {
      bytes32 betId = oraclize_newRandomDSQuery(DELAY, N, CALLBACK_GAS);
      betIds[i] = betId;
      betIdToIndex[betId] = i+1;
    }
  }

  function __callback(bytes32 betId, string result, bytes proof) public
    onlyOraclize
    onlyIfBetExists(betId)
    oraclize_randomDS_proofVerify(betId, result, proof)
  {
    numDigitsLeft--;
    byte resultByte = byte((uint(bytes(result)[0]) % MODULO) + 1);
    OraclizeResultByte(resultByte);
    lotteryResult[betIdToIndex[betId]-1] = resultByte;
    if (numDigitsLeft == 0) {
      notifyGame();
    }
  }

  function notifyGame() internal {
    lotteryGame.receiveResult(lotteryResult);
  }

  function resetGameAddress(address _lotteryGameAddress) onlyOwner public {
    lotteryGame = LotteryGame(_lotteryGameAddress);
  }

}
