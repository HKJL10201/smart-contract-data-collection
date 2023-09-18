// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase {
  bytes32 internal keyHash; // identifies which Chainlink oracle to use
  uint256 internal fee; // fee to get random number
  uint256 public randomResult;

  address public owner;
  address payable[] public players;

  uint256 public lotteryId;
  mapping(uint256 => address payable) public lotteries;

  modifier onlyOwner() {
    require(owner == msg.sender, "Only owner");
    _;
  }

  constructor()
    VRFConsumerBase(
      0x6168499c0cFfCaCD319c818142124B7A15E857ab, // VRF coordinator
      0x01BE23585060835E02B77ef475b0Cc51aA1e0709 // LINK token address
    )
  {
    keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    fee = 0.25 * 10**18; // 0.25 LINK

    owner = msg.sender;
  }

  function getRandomNumber() public returns (bytes32 requestId) {
    require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK in contract");
    return requestRandomness(keyHash, fee);
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    randomResult = randomness;
  }

  function enter() public payable {
    require(msg.value > .01 ether, "Insufficient funds");

    players.push(payable(msg.sender));
  }

  function pickWinner() public onlyOwner {
    uint256 index = randomResult % players.length;
    address payable winner = players[index];

    lotteries[lotteryId] = players[index];
    lotteryId++;

    players = new address payable[](0);

    (bool sent, bytes memory data) = winner.call{value: address(this).balance}("");
    require(sent, "Failed to send Ether");
  }

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function getPlayers() public view returns (address payable[] memory) {
    return players;
  }

  function getWinnerByLottery(uint256 _lotteryId) public view returns (address payable) {
    return lotteries[_lotteryId];
  }
}
