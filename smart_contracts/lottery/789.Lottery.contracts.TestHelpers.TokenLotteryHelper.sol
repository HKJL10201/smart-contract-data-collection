// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../TokenLottery.sol";

contract TokenLotteryHelper is TokenLottery {

  address ownr = address(0x19FF17645bd4930745e632284422555466675e44);

  constructor() TokenLottery("Tokens Lottery", 0, 1000000000000000000, 10, IERC20(0x0000000000000000000000000000000000000000), 30000000000000000, ownr) {
  }

  function updateTokenAddress(IERC20 _inputToken) public returns (bool) {
    inputToken = _inputToken;
    return true;
  }

  function checkRandomness() public view returns (uint[5] memory) {
    return [generateRandomNumber(), (generateRandomNumber() % 5),block.number, block.timestamp, ticketCounter];
  }

  function getTokenAddress() public view returns (IERC20) {
    return inputToken;
  }

  function viewWinningsByAddress(address addr) public view returns (uint) {
    return debtToUser[addr];
  }

  function viewCurrentDraw() public view returns (uint) {
    return currentDraw;
  }

  function didSomeoneWin() public view returns (bool) {
    return !(lottos[currentLotto-1].winningTicket == bytes32(0));
  }

  function viewStart() public view returns(uint) {
    return lottos[currentLotto].startTime;
  }


  function viewLast() public view returns(uint) {
    return lottos[currentLotto].lastDraw;
  }

  function viewPot() public view returns(uint) {
    return lottos[currentLotto].totalPot;
  }

  function viewLastPot() public view returns(uint) {
    return lottos[currentLotto-1].totalPot;
  }

  function viewWinner() public view returns(bytes32) {
    return lottos[currentLotto-1].winningTicket;
  }

  function viewFinished() public view returns(bool) {
    return lottos[currentLotto-1].finished;
  }

  function viewTicketCount() public view returns(uint) {
    return ticketCounter;
  }

  function viewLottoNumber() public view returns(uint) {
    return currentLotto;
  }
}
