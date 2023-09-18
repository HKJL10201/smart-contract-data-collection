pragma solidity ^0.4.19;

import './ERC223ReceivingContract.sol';
import './PayoutBacklogStorage.sol';

import './LotteryStorageLib.sol';
import './LotteryLib.sol';

import 'zeppelin-solidity/contracts/lifecycle/TokenDestructible.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';

contract LotteryGame is ERC223ReceivingContract, TokenDestructible {
  using LotteryStorageLib for LotteryStorageLib.LotteryStorage;
  using LotteryLib for LotteryLib.Lottery;
  using SafeMath for uint256;

  event LogNonUILotteryEntry(address indexed player, bytes lottery);
  event LogUIConfirmEntry(address indexed player, byte[6] lottery);
  event LogLotteryResult(byte[6] result);
  event LogPrizeWinners(uint indexed prizeIndex, address[] winners);
  event LogLotteryEntry(byte[6] entry);

  /** ticket price in YOLO token */
  uint public ticketPriceYolo;
  /** ticket price in eth */
  uint public ticketPriceEth;
  /** prize values */
  uint[5] public payoutValues;
  /** payout period */
  uint[5] public payoutPeriods;
  /** payout backlog */
  PayoutBacklogStorage public payoutBacklogStorage;

  /** lottery ticket storage */
  LotteryStorageLib.LotteryStorage lotteryStorage;
  /** lottery placeholder variable */
  LotteryLib.Lottery lottery;
  /** payout threshold. since eth gas price, small prizes will be stored in the backlog
    * and distributed once it passes this threshold */
  uint public payoutThreshold;
  /** address of the lottery result generator */
  address public resultGeneratorAddress;

  modifier onlyResultGenerator() {
    if (msg.sender != resultGeneratorAddress) throw;
    _;
  }

  /**
    * constructor
    * @param _payoutBacklogStorageAddress jackpot address to distribute funds from
    * @param _ticketPriceEth ticket price in eth for people buying lottery in eth
    * @param _ticketPriceYolo ticket price in YOLO token for people buying via YOLO token
    * @param _payoutValues prizes in eth for grand prize to smallest prizes
    * @param _payoutPeriods number of weeks it takes to distribute prizes to winners. 1 measn distribute at once
  **/
  function LotteryGame(address _payoutBacklogStorageAddress, uint _ticketPriceEth, uint _ticketPriceYolo, uint[5] _payoutValues, uint[5] _payoutPeriods) {
    payoutBacklogStorage = PayoutBacklogStorage(_payoutBacklogStorageAddress);
    ticketPriceEth = _ticketPriceEth;
    ticketPriceYolo = _ticketPriceYolo;
    payoutValues = _payoutValues;
    payoutPeriods = _payoutPeriods;
  }

  /** lottery entry through non-ui channels. ie:  */
  function () external payable {
    require(msg.value >= ticketPriceEth);
    LogNonUILotteryEntry(msg.sender, msg.data);
    lotteryStorage.enterLottery(lottery, msg.data, msg.sender);
  }

  /** lottery entry through ui */
  function enterLottery(byte[6] entry, bool fromWebUI) public payable {
    require(msg.value >= ticketPriceEth);
    if (fromWebUI) {
      /** necessary for entries passed through web3 but not metamask or remix */
      for (uint i = 0; i < 6; i++) {
        entry[i] = (entry[i] >> 4);
      }
    }
    lotteryStorage.enterLottery(lottery, entry, msg.sender);
    LogUIConfirmEntry(msg.sender, entry);
  }

  /** notification of lottery result */
  function receiveResult(byte[6] result) public onlyResultGenerator {
    LogLotteryResult(result);
    processResult(result);
  }

  /** internal helper function */
  function processResult(byte[6] result) internal {
    for (uint i = 0; i < lotteryStorage.numLotteries(); i++) {
      LotteryLib.Lottery storage entry = lotteryStorage.lotteries[i];
      uint prizeIndex = getPrizeIndex(entry, result);
      if (prizeIndex <= 4) {
        address[] memory prizeWinners = lotteryStorage.getWinners(entry);
        LogPrizeWinners(prizeIndex, prizeWinners);
        LogLotteryEntry(entry.ticket);
        addPrizesToBacklog(prizeWinners, prizeIndex);
      }
    }
    payoutBacklogStorage.pay(payoutThreshold);
  }

  /** add grand prize, 5-number match, 4-number match to the backlog, and pay them in subsequent weeks
    * @param prizeWinners winners we need to add to the backlog
    * @param prizeIndex prize that they won (0 is grand prize, 1 is 5-num match, etc)
  **/
  function addPrizesToBacklog(address[] prizeWinners, uint prizeIndex) internal {
    uint numPrizeWinners = prizeWinners.length;
    if (numPrizeWinners > 0) {  // check shouldn't be necessary, for extra safety
      uint payoutAmount = payoutValues[prizeIndex].div(payoutPeriods[prizeIndex]).div(numPrizeWinners);
      for (uint i = 0; i < numPrizeWinners; i++) {
        payoutBacklogStorage.addPrizeToWinner(prizeWinners[i], payoutAmount, payoutPeriods[prizeIndex]);
      }
    }
  }

  /** get what prize each lottery ticket won, 0 means grand prize, 1 is 5-num match, etc. */
  function getPrizeIndex(LotteryLib.Lottery storage entry, byte[6] result) internal returns (uint) {
    return entry.getNumNotMatching(result);
  }

  /** sets the prize value for each prize, default definded in `settings.json` */
  function resetPrize(uint index, uint value) public onlyOwner {
    payoutValues[index] = value;
  }

  /** sets the payout period for each prize, default definded in `settings.json` */
  function resetPrizePayoutPeriod(uint index, uint period) public onlyOwner {
    payoutPeriods[index] = period;
  }
  
  /** sets the ticket price in eth for each lottery ticket. default defined in `settings.json` */
  function setTicketPriceEth(uint _ticketPriceEth) public onlyOwner {
    ticketPriceEth = _ticketPriceEth;
  }

  /** sets the ticket price in YOLO token for each lottery ticket. default defined in `settings.json` */
  function setTicketPriceYolo(uint _ticketPriceYolo) public onlyOwner {
    ticketPriceYolo = _ticketPriceYolo;
  }

  /** sets the lottery result generator address. only this address can announce lottery result */
  function setResultGeneratorAddress(address _resultGeneratorAddress) public onlyOwner {
    resultGeneratorAddress = _resultGeneratorAddress;
  }
  
  /** sets the payout threshold. if win value is less than this threshold, we hold until a later date to distribute
      a payout to this winner */
  function setPayoutThreshold(uint _payoutThreshold) onlyOwner {
    payoutThreshold = _payoutThreshold;
  }

  /** good to have functions */
  function withdraw(uint amount) public onlyOwner {
    owner.transfer(amount);
  }

  /** reset tickets in lottery and start new round */
  function startNewRound() public onlyOwner {
    LotteryStorageLib.LotteryStorage storage _lotteryStorage;
    lotteryStorage = _lotteryStorage;
  }

  /** in case any logic changes in payout storage */
  function resetPayoutStorage(address _payoutBacklogStorageAddress) onlyOwner public {
    payoutBacklogStorage = PayoutBacklogStorage(_payoutBacklogStorageAddress);
  }

  function resetPayoutStorageOwnership() onlyOwner public {
    payoutBacklogStorage.transferOwnership(owner);
  }
  
  /** implementation of erc-223. transfer function of YOLO tokens calls this function in the contract */
  function tokenFallback(address _from, uint _value, bytes _data) public {
    require(_value > ticketPriceYolo);
    LogNonUILotteryEntry(_from, _data);
    lotteryStorage.enterLottery(lottery, _data, msg.sender);
  }

  /** helper functions to read contents of the game */
  function getNumLotteries() public returns(uint) {
    return lotteryStorage.numLotteries();
  }
  
  function getLotteryAtIndex(uint index) public returns(byte[6]) {
    LotteryLib.Lottery memory entry = lotteryStorage.getLottery(index);
    return entry.ticket;
  }
  
  function getPlayerAddressesAtIndex(uint index) public returns(address[]) {
    LotteryLib.Lottery storage entry = lotteryStorage.lotteries[index];
    address[] memory prizeWinners = lotteryStorage.getWinners(entry);
    return prizeWinners;
  }

}
