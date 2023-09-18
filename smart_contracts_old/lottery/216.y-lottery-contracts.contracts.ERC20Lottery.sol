// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "./Lottery.sol";

contract ERC20Lottery is Lottery {
  // add the library methods
  using Counters for Counters.Counter;
  using EnumerableMap for EnumerableMap.UintToAddressMap;
  using SafeERC20 for IERC20;

  // ERC20 token
  IERC20 internal token;
  address internal tokenAddress;

  constructor(
    address _tokenAddress,
    bool _strict,
    uint256 _ticketPrice,
    uint256 _maxParticipants,
    uint256 _maxDuration,
    uint256 _fee,
    address _manager
  )
    Lottery(
      _strict,
      _ticketPrice,
      _maxParticipants,
      _maxDuration,
      _fee,
      _manager
    )
  {
    token = IERC20(_tokenAddress);
    tokenAddress = _tokenAddress;
  }

  // ///////
  // getters
  // ///////

  // get the lottery info
  // =>

  function getInfo()
    external
    view
    override
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
      tokenAddress
    );
  }

  // ////////////////
  // internal methods
  // ////////////////

  // pay reward
  // =>

  function payReward(address winner) internal override {
    uint256 commission = (tokens * fee) / 10000;
    uint256 reward = tokens - commission;

    // pay commission
    // =>

    if (commission > 0) {
      token.transfer(manager, commission);
      emit SendCommission(commission, manager);
    }

    // pay rewards
    // =>

    token.transfer(winner, reward);
    emit SendRewards(
      reward,
      winner,
      participants[winner].tickets * ticketPrice
    );
  }

  // ////////////////
  // external methods
  // ////////////////

  // enter to the lottery
  // =>

  function enter(uint256 ticketsToBePurchased) external payable override {
    require(msg.value == 0, "INCORRECT_TICKETS_COST");

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

    // spend amount
    // =>

    uint256 amount = ticketPrice * ticketsToBePurchased;

    // check allowance
    // =>

    require(
      token.allowance(msg.sender, address(this)) >= amount,
      "ALLOWANCE_TOO_LOW"
    );

    // buy tickets
    // =>

    token.safeTransferFrom(msg.sender, address(this), amount);
    participants[msg.sender].tickets += ticketsToBePurchased;
    tickets += ticketsToBePurchased;
    tokens += amount;

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
}
