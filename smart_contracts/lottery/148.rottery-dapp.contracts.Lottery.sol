//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Lottery is Ownable, AccessControl {
  /* stores player addresses in an array where the index is the ticket number */
  address[] public ticketsArray;
  /* stores a list of tickets bought by each address */
  mapping(address => uint256[]) public playerTickets;
  /* keeps track of the next ticket number to be issued */
  uint256 public ticketCounter;
  /* last winning ticket number */
  uint256 public prevWinningTicket;
  /* current prize pool */
  uint256 public prizePool;
  /* previous prize pool */
  uint256 public prevPrizePool;
  /* price of one ticket */
  uint256 public ticketPrice;
  /* portion of the funds set aside for the owner */
  uint256 public usageFees;
  /* epoch timestamp of when the lottery is becomes open */
  uint256 public lockedUntil;
  /* mod role hash */
  bytes32 public constant MOD_ROLE = keccak256("MOD_ROLE");
  /* an event that signifies a change in lottery state requiring a UI update */
  event LotteryChange(uint256 timestamp);

  constructor() {
    _setupRole(MOD_ROLE, owner());
    ticketPrice = 20 ether;
    lockedUntil = block.timestamp;
  }

  function mod(address mod1, address mod2) external onlyOwner {
    _setupRole(MOD_ROLE, mod1);
    _setupRole(MOD_ROLE, mod2);
  }

  function enter(address tokenAddress, uint256 numTickets) external {
    require(block.timestamp > lockedUntil);
    uint256 amountMantissa = numTickets * ticketPrice;
    ERC20(tokenAddress).transferFrom(msg.sender, address(this), amountMantissa);
    for (uint256 t = 0; t < numTickets; t++) {
      _createTicket();
    }
    uint256 usageFeesCut = (amountMantissa * 100) / 5;
    prizePool += (amountMantissa - usageFeesCut);
    usageFees += usageFeesCut;
    emit LotteryChange(block.timestamp);
  }

  function _createTicket() internal {
    ticketsArray.push(msg.sender);
    playerTickets[msg.sender].push(ticketCounter);
    ticketCounter++;
  }

  function _pseudoRandom() internal view returns (uint256) {
    uint256 randomHash =
      uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    return (randomHash % ticketCounter);
  }

  function pickWinner(address tokenAddress) external {
    require(hasRole(MOD_ROLE, msg.sender), "Caller must be a mod");
    require(block.timestamp > lockedUntil, "lottery locked");
    lockedUntil = block.timestamp + 5 minutes;
    uint256 winningTicket = _pseudoRandom();
    ERC20(tokenAddress).transfer(ticketsArray[winningTicket], prizePool);
    resetLottery(winningTicket);
    emit LotteryChange(block.timestamp);
  }

  function withdrawFees(address tokenAddress) external onlyOwner {
    ERC20(tokenAddress).transfer(owner(), usageFees);
    usageFees = 0;
  }

  function resetLottery(uint256 winningTicket) internal {
    prevWinningTicket = winningTicket;
    prevPrizePool = prizePool;
    prizePool = 0;
    ticketCounter = 0;
    // TODO: more efficient delete?
    for (uint256 i = 1; i < ticketsArray.length; i++) {
      delete playerTickets[ticketsArray[i]];
    }
  }

  function getMyTickets() external view returns (uint256[] memory) {
    return playerTickets[msg.sender];
  }
}
