pragma solidity ^0.5.0;

import "./PayoffAuctionList.sol";

contract CommitRevealAuctionList is PayoffAuctionList {

  struct BidCommit {
    uint auctionId;
    bytes32 bidHash;
    uint blockNumber;
  }

  event BidCommitted(
    uint auctionId,
    bytes32 bidHash,
    uint blockNumber
  );

  mapping(address => BidCommit) public commits;

  function commit(uint auctionId, bytes32 bidHash) public auctionLive(auctionId) {
    commits[msg.sender] = BidCommit(auctionId, bidHash, block.number);
    emit BidCommitted(auctionId, bidHash, block.number);
  }

  function reveal(uint auctionId, uint256 bid, uint256 randomNonce) public payable auctionLive(auctionId) {
    require(commits[msg.sender].blockNumber + 100 <= block.number, "Too early reveal");
    require(commits[msg.sender].bidHash == hash(auctionId, bid, randomNonce), "Incorrect hash");
    makeBid(auctionId, bid);
  }

  function hash(uint auctionId, uint256 bid, uint256 randomNonce) public view returns (bytes32 result) {
    return keccak256(abi.encodePacked(msg.sender, auctionId, bid, randomNonce));
  }
}