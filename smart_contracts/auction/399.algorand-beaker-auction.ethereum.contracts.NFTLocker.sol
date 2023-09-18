// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTLocker {

  string public name = "NFT Locker";

  address public owner;
  address public winner;

  uint256 public releaseTime;

  event TokenLocked(address token, uint256 tokenId, uint256 releaseTime);
  event TokenUnlocked(address token, uint256 tokenId);
  event Winner(address winner);

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(owner == msg.sender, "ERROR: ONLY OWNER");
     _;
  }

  function lock(address token, uint256 tokenId, uint256 _releaseTime) external  {
    require(IERC721(token).getApproved(tokenId) == address(this), "Locker Contract Not Approved.");
    require(releaseTime == 0, "Token already locked");
    releaseTime = _releaseTime;
    IERC721(token).transferFrom((msg.sender), address(this), tokenId);
    emit TokenLocked(token, tokenId, releaseTime);
  }

  function setWinner(address _winner) external onlyOwner {
    require(winner == address(0), "Winner already set");
    winner = _winner;
    emit Winner(_winner);
  }

  function unlock(address token, uint256 tokenId) external {
    require(block.timestamp > releaseTime, "Too early to unlock.");
    require(msg.sender == winner, "You are not the winner.");
    winner = address(0);
    releaseTime = 0;
    IERC721(token).transferFrom(address(this), winner, tokenId);
    emit TokenUnlocked(token, tokenId);
  }
}