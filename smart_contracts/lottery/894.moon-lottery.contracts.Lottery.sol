// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./access/Ownable.sol";

contract Lottery is Ownable {
  uint256 numberToFind;
  uint256 randNonce = 0;
  uint256 modulus;
  uint256 ticketValue;
  mapping (address => bool) hasPlayed;
  address[] playerAddresses;

  event TicketBought(address indexed from, bool isWinningTicket);

  constructor(uint256 _modulus, uint256 _ticketValue) {
    modulus = _modulus;
    ticketValue = _ticketValue;
    numberToFind = generateRandomNumber(modulus);
  }

  function generateRandomNumber(uint256 _modulus) internal returns (uint256) {
    randNonce++;
    return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % _modulus;
  }

  function resetLottery() internal {
    numberToFind = generateRandomNumber(modulus);
    for (uint256 i = 0; i < playerAddresses.length; i++) {
      address currentAddress = playerAddresses[i];
      hasPlayed[currentAddress] = false;
    }
    delete playerAddresses;
  }

  function sendFunds() internal returns (bool) {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    return success;
  }

  function getNumber() public view onlyOwner returns (uint) {
    return numberToFind;
  }

  function setTicketValue(uint256 _ticketValue) public onlyOwner {
    ticketValue = _ticketValue;
  }

  function getTicketValue() public view returns (uint256) {
    return ticketValue;
  }

  function setModulus(uint256 _modulus) public onlyOwner {
    modulus = _modulus;
  }

  function guessNumber(uint256 _guess) payable public {
    require(msg.value == ticketValue, "Incorrect ticket value received");
    playerAddresses.push(msg.sender);
    hasPlayed[msg.sender] = true;

    if (_guess == numberToFind) {
      // Sender has won the game, and gains the balance of the smart contract.
      bool fundsSent = sendFunds();
      require(fundsSent, "Funds could not be sent to player");
      resetLottery();
      emit TicketBought(msg.sender, true);
    } else {
      // Sender guessed wrong and cannot try again until someone wins.
      emit TicketBought(msg.sender, false);
    }
  }
}