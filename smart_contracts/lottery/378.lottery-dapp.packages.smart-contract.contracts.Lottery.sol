// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract Lottery is AccessControl {
  using SafeMath for uint256;

  /* ============ Variables ============ */

  // roles
  bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');

  // contract of MockToken
  IERC20 public mockToken;

  // price of a ticket
  uint256 public ticketPrice;

  // fee of the lottery
  uint256 public feeRate = 500; // 5% in two decimal places

  /**
   * Past Lotteries
   */

  // struct for finished lottery
  struct PastLottery {
    uint256 jackpot;
    uint256 winningTicket;
    address winner;
    uint256 drawnTimestamp;
  }

  // array of past lotteries
  PastLottery[] public pastLotteries;

  /**
   * Current Lottery
   */

  // purchaser array of the current lottery
  address[] private currentPlayers;

  // jackpot of the current lottery
  uint256 public currentPrizePoolAmount;

  // fees that have not been withdrawn yet
  uint256 public withdrawableFeeAmount;

  /* ============ Events ============ */

  event TicketPriceChanged(uint256 ticketPrice);
  event FeeRateChanged(uint256 feeRate);
  event TicketPurchased(address buyer, uint256 ticketAmount, uint256 totalCost);
  event Drawn(uint256 winningTicket, address winner, uint256 prizeAmount);
  event Withdrawn(uint256 feeAmount);

  /* ============ Constructor ============ */

  constructor(
    address _mockTokenAddress,
    uint256 _ticketPrice,
    uint256 _feeRate
  ) {
    mockToken = IERC20(_mockTokenAddress);
    ticketPrice = _ticketPrice;
    feeRate = _feeRate;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  /* ============ External Functions ============ */

  // buy ticket
  function buyTicket(uint256 _ticketAmount) external {
    // transfer total cost to this contract
    uint256 totalCost = ticketPrice.mul(_ticketAmount);
    mockToken.transferFrom(msg.sender, address(this), totalCost);

    // store the fee amount
    uint256 fee = totalCost.mul(feeRate).div(10000);
    withdrawableFeeAmount = withdrawableFeeAmount.add(fee);

    // store the remaining as current jackpot
    uint256 remaining = totalCost.sub(fee);
    currentPrizePoolAmount = currentPrizePoolAmount.add(remaining);

    // add player to the list
    for (uint256 i = 0; i < _ticketAmount; i++) {
      currentPlayers.push(msg.sender);
    }

    emit TicketPurchased(msg.sender, _ticketAmount, totalCost);
  }

  // purchased tickets
  function ticketsOf(address _player) external view returns (uint256) {
    uint256 count = 0;
    for (uint256 i = 0; i < currentPlayers.length; i++) {
      if (currentPlayers[i] == _player) {
        count++;
      }
    }
    return count;
  }

  function pastLotteryCount() external view returns (uint256) {
    return pastLotteries.length;
  }

  /* ============ Admin Functions ============ */

  // set ticket price
  function setTicketPrice(uint256 _ticketPrice) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Caller is not an admin');
    ticketPrice = _ticketPrice;
    emit TicketPriceChanged(_ticketPrice);
  }

  // set fee rate
  function setFeeRate(uint256 _feeRate) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Caller is not an admin');
    require(_feeRate <= 10000, 'Fee rate must be 10000 or less');
    feeRate = _feeRate;
    emit FeeRateChanged(_feeRate);
  }

  // draw lottery
  function draw() external {
    require(
      hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
        hasRole(MANAGER_ROLE, msg.sender),
      'Caller is neither an admin nor a manager'
    );
    require(currentPlayers.length > 0, 'No players have purchased tickets');

    // check if 5 minutes have passed since the last draw
    uint256 currentTime = block.timestamp;
    if (pastLotteries.length > 0) {
      require(
        currentTime >=
          pastLotteries[pastLotteries.length - 1].drawnTimestamp + 5 minutes,
        'You can only draw once every 5 minutes'
      );
    }

    // determine winner
    uint256 winningTicket = _pickWinningTicket();
    address winner = currentPlayers[winningTicket];

    // push the lottery to the past lotteries
    pastLotteries.push(
      PastLottery(currentPrizePoolAmount, winningTicket, winner, currentTime)
    );

    // prize payment

    // winner gets all of the prize pool
    mockToken.transfer(winner, currentPrizePoolAmount);

    // emit event
    emit Drawn(winningTicket, winner, currentPrizePoolAmount);

    // reset current lottery state

    // clear players
    delete currentPlayers;

    // clear prize pool
    currentPrizePoolAmount = 0;
  }

  // withdraw fee
  function withdraw() external {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Caller is not an admin');

    // transfer the fee stored in this contract to admin
    mockToken.transfer(msg.sender, withdrawableFeeAmount);

    // emit event
    emit Withdrawn(withdrawableFeeAmount);

    // reset the fee amount
    withdrawableFeeAmount = 0;
  }

  /* ============ Internal Functions ============ */

  // pick a random ticket index from the current players
  function _pickWinningTicket() internal view returns (uint256) {
    // generate random between 0 and currentPlayers.length - 1
    return _random() % currentPlayers.length;
  }

  // generate a pseudo random number
  function _random() internal view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(block.difficulty, block.timestamp, currentPlayers)
        )
      );
  }
}
