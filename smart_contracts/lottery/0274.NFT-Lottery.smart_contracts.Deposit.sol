pragma solidity ^0.5.0;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// TODO: needs security check, see: https://forum.enigma.co/t/enigmasimulation/1070/16?u=nioni
contract Deposit is Ownable, IERC721Receiver {
  enum LotteryStatus {
    JOINING,
    READY,
    COMPLETE
  }

  struct Lottery {
    uint256 id;
    uint256 token_id;
    uint256 participants;
    uint256 max_participants;
    address contract_addr;
    address winner;
    LotteryStatus status;
  }

  uint256 public lotteriesLength = 0;
  mapping(uint256 => Lottery) public lotteries;

  // TODO: this should be guarded so only secret contract can call it
  function lotteryCreated(
    uint256 id,
    uint256 token_id,
    uint256 max_participants,
    address contract_addr,
    address from
  ) external {
    ERC721(contract_addr).safeTransferFrom(from, address(this), token_id);

    lotteries[id] = Lottery(
      id,
      token_id,
      0,
      max_participants,
      contract_addr,
      address(0),
      LotteryStatus(0)
    );

    lotteriesLength = lotteriesLength + 1;
  }

  // TODO: this should be guarded so only secret contract can call it
  function userJoined(uint256 id, uint256 status) external {
    lotteries[id].participants = lotteries[id].participants + 1;
    lotteries[id].status = LotteryStatus(status);
  }

  // TODO: this should be guarded so only secret contract can call it
  function winnerSelected(uint256 id, address winner) external {
    ERC721(lotteries[id].contract_addr).safeTransferFrom(address(this), winner, lotteries[id].token_id);

    lotteries[id].winner = winner;
    lotteries[id].status = LotteryStatus(2);
  }

  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes memory _data
  ) public returns(bytes4) {
    return this.onERC721Received.selector;
  }
}