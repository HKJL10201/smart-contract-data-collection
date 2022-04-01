// SPDX-License-Identifier: UNLICENSED

// This is the version of the Solidity compiler we want our contract to use.
pragma solidity ^0.8.0;

// Some magic given to us by Hardhat to do some console logs in our contract.
import "hardhat/console.sol";

contract WavePortal {
  uint256 totalWaves;

  /*
  * We will be using this below to help generate a random number
  */
  uint256 private seed;

  // Event declaration where I specify the signature.
  event NewWave(address indexed from, uint256 timestamp, string message, uint256 prizeAmount);

  /*
  * I created a struct here named Wave.
  * A struct is basically a custom datatype where we can customize what we want to hold inside it.
  */
  struct Wave {
    address from; // The address of the user who waved.
    string message; // The message the user sent.
    uint256 timestamp; // The timestamp when the user waved.
    uint256 prizeAmount; // The amount of prize the user won.
  }

  /*
  * I declare a variable waves that lets me store an array of structs.
  * This is what lets me hold all the waves anyone ever sends to me!
  */
  Wave[] waves;

  /*
  * This is an address => uint mapping, meaning I can associate an address with a number!
  * In this case, I'll be storing the address with the last time the user waved at us.
  */
  mapping(address => uint256) public lastWavedAt;

  // Once we initialize this contract for the first time, that constructor
  // will run and print out that line.
  constructor() payable {
    console.log("Hey, let's do de WAVE!");

    // Set the initial seed.
    seed = (block.timestamp + block.difficulty) % 100;
  }

  function wave(string memory _message) public {
    // We need to make sure the current timestamp is at least 15-minutes
    // bigger than the last timestamp we stored.
    require(lastWavedAt[msg.sender] + 30 seconds < block.timestamp, "Must wait 30 seconds before waving again.");
    // require(
    //   lastWavedAt[msg.sender] + 15 minutes < block.timestamp,
    //   "Wait 15m"
    // );

    // Update the current timestamp we have for the user.
    lastWavedAt[msg.sender] = block.timestamp;

    totalWaves += 1;
    console.log("%s has waved w/ message ", msg.sender, _message);

    // Generate a new seed for the next user that sends a wave.
    seed = (block.difficulty + block.timestamp + seed) % 100;

    if (seed <= 50) {
      console.log("%s won!", msg.sender);

      // The same code we had before to send the prize.
      uint256 prizeAmount = 0.0001 ether;
      require(
          prizeAmount <= address(this).balance,
          "Trying to withdraw more money than the contract has."
      );

      // we send money.
      (bool success, ) = (msg.sender).call{value: prizeAmount}("");
      require(success, "Failed to withdraw money from contract.");

      // This is where I actually store the wave data in the array.
      waves.push(Wave(msg.sender, _message, block.timestamp, prizeAmount));

      // This is where I emit the event for the winner.
      emit NewWave(msg.sender, block.timestamp, _message, prizeAmount);

      return;
    }

    // This is where I actually store the wave data in the array.
    waves.push(Wave(msg.sender, _message, block.timestamp, 0 ether));

    // This is where I emit the standart event.
    emit NewWave(msg.sender, block.timestamp, _message, 0 ether);
  }

  /*
  * I added a function getAllWaves which will return the struct array, waves, to us.
  * This will make it easy to retrieve the waves from our website!
  */
  function getAllWaves() public view returns (Wave[] memory) {
    return waves;
  }

  function getTotalWaves() public view returns (uint256) {
    console.log("We have %d total waves!", totalWaves);
    return totalWaves;
  }
}
