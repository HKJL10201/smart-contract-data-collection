// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

contract Lottery is Ownable {
  // add the library methods
  using Counters for Counters.Counter;
  using EnumerableMap for EnumerableMap.UintToAddressMap;

  enum State {
    Inactive,
    Active
  }

  // lottery state
  State internal state;

  // participant data
  struct Participant {
    // total tickets purchased by participant
    uint256 tickets; // default: 0
  }

  // enumerable map of participants addresses,
  // represents index => address
  EnumerableMap.UintToAddressMap internal addresses;

  // map of participants data,
  // represents address => Participant
  mapping(address => Participant) internal participants;

  // current participants counter
  Counters.Counter internal counter;

  // manager (fee receiver)
  address internal manager;

  // ticket price
  uint256 internal ticketPrice;

  // max participatns, once the maximum number of participants has been reached,
  // the lottery will be locked and a winner will have to be determined
  uint256 internal maxParticipants;

  // max duration
  uint256 internal maxDuration;

  // service fee
  uint256 internal fee;

  // end time
  uint256 internal endTime;

  // total tickets purchased
  uint256 internal tickets;

  // bonded tokens
  uint256 internal tokens;

  // strict/unlimited mode
  // in strict mode the participant can only buy one ticket,
  // otherwise any number is available for purchase
  bool internal strict;

  constructor(
    bool _strict,
    uint256 _ticketPrice,
    uint256 _maxParticipants,
    uint256 _maxDuration,
    uint256 _fee,
    address _manager
  ) {
    require(_ticketPrice > 0, "INVALID_TICKET_PRICE");
    state = State.Active;
    strict = _strict;
    ticketPrice = _ticketPrice;
    maxParticipants = _maxParticipants;
    maxDuration = _maxDuration;
    fee = _fee;
    manager = _manager;
    endTime = block.timestamp + maxDuration;
  }

  // //////
  // events
  // //////

  event LotteryDeactivated();
  event SendCommission(uint256 amount, address indexed to);
  event SendRewards(uint256 amount, address indexed to, uint256 paid);

  // ///////
  // getters
  // ///////

  // get number of tickets for specific address
  // =>

  function getAddressTickets(address addr) external view returns (uint256) {
    return participants[addr].tickets;
  }

  // get the lottery info
  // =>

  function getInfo()
    external
    view
    virtual
    returns (
      // current state
      State,
      // strict mode?
      bool,
      // ticket price
      uint256,
      // current number of participants
      uint256,
      // max number of participants
      uint256,
      // end time
      uint256,
      // max duration
      uint256,
      // total tickets purchased
      uint256,
      // bonded tokens
      uint256,
      // fee
      uint256,
      // manager address
      address,
      // token address
      address
    )
  {
    return (
      state,
      strict,
      ticketPrice,
      counter.current(),
      maxParticipants,
      endTime,
      maxDuration,
      tickets,
      tokens,
      fee,
      manager,
      address(0)
    );
  }

  // ///////
  // helpers
  // ///////

  // generate pseudo random uint256
  // =>

  function pseudoRandom() private view returns (uint256) {
    // 👀
    return
      uint256(
        keccak256(
          abi.encodePacked(
            blockhash(block.number - 1),
            block.coinbase,
            block.difficulty,
            tokens + tickets
          )
        )
      );
  }

  // ///////////////
  // private methods
  // ///////////////

  // restart the lottery (reset state)
  // =>

  function restart() private {
    for (uint256 i = 0; i < counter.current(); i++) {
      delete participants[addresses.get(i)];
      addresses.remove(i);
    }

    counter.reset();
    tickets = 0;
    tokens = 0;
  }

  // ////////////////
  // internal methods
  // ////////////////

  // pay reward
  // =>

  function payReward(address winner) internal virtual {
    uint256 commission = (tokens * fee) / 10000;
    uint256 reward = tokens - commission;

    // pay commission
    // =>

    if (commission > 0) {
      payable(manager).transfer(commission);
      emit SendCommission(commission, manager);
    }

    // pay rewards
    // =>

    payable(winner).transfer(reward);
    emit SendRewards(
      reward,
      winner,
      participants[winner].tickets * ticketPrice
    );
  }

  // pick the winner
  // =>

  function pickWinner() internal {
    if (counter.current() == 0) {
      restart();
      return;
    }

    uint256 rnd = pseudoRandom() % (strict ? counter.current() : tickets);

    if (strict) {
      payReward(addresses.get(rnd));
      restart();
      return;
    }

    uint256 ticketsLooped = 0;

    for (uint256 i = 0; i < counter.current(); i++) {
      // check participatns tickets range
      // rnd: 2
      // 0: 1 ticket (1)
      // 1: 2 tickets (2, 3) <= the winner
      // 2: 1 ticket (4)
      // ...
      // =>

      if (
        rnd >= ticketsLooped &&
        rnd <= ticketsLooped + participants[addresses.get(i)].tickets - 1
      ) {
        payReward(addresses.get(i));
        restart();
        return;
      }

      ticketsLooped += participants[addresses.get(i)].tickets;
    }

    // will never be reached
  }

  // ////////////////
  // external methods
  // ////////////////

  // enter to the lottery
  // =>

  function enter(uint256 ticketsToBePurchased) external payable virtual {
    // check state
    // =>

    require(state == State.Active, "INVALID_STATE");

    // check the possibility of buying tickets
    // =>

    require(
      !strict || participants[msg.sender].tickets == 0,
      "IMPOSSIBLE_TO_BUY_MORE"
    );

    // check tickets amount
    // in strict mode the participant can only buy one ticket,
    // otherwise any number is available for purchase
    // =>

    require(
      strict ? ticketsToBePurchased == 1 : ticketsToBePurchased > 0,
      "INCORRECT_TICKETS_AMOUNT"
    );

    // check tickets cost
    // =>

    require(
      strict
        ? msg.value == ticketPrice
        : msg.value / ticketPrice == ticketsToBePurchased &&
          msg.value % ticketPrice == 0,
      "INCORRECT_TICKETS_COST"
    );

    // buy tickets
    // =>

    participants[msg.sender].tickets += ticketsToBePurchased;
    tickets += ticketsToBePurchased;
    tokens += msg.value;

    // add new participant
    // =>

    if (participants[msg.sender].tickets == ticketsToBePurchased) {
      addresses.set(counter.current(), msg.sender);
      counter.increment();

      // start the countdown after the first participant is come
      // =>

      if (counter.current() == 1) {
        endTime = block.timestamp + maxDuration;
      }
    }

    // pick the winner if max participants reached
    // =>

    if (counter.current() == maxParticipants || block.timestamp >= endTime) {
      pickWinner();
    }
  }

  // terminate immediately
  // =>

  function terminate(bool deactivate) external onlyOwner {
    pickWinner();

    // 🔒
    if (deactivate) {
      state = State.Inactive;
      emit LotteryDeactivated();
    }
  }
}
