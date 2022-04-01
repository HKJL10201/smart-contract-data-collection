// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.2;

contract RevenueStream {

  uint public fee;
  address public treasury;
  address public self = address(this);

  uint public fantomDebtToRecipient;
  mapping(IERC20 => uint) public TokenDebtToRecipient;

  uint public constant ftmDecimals = 1000000000000000000;

  function feeCalc(uint _total) internal view returns (uint) {
    uint _rake = (_total * fee) / ftmDecimals;
    return(_rake);
  }

  function takeFantomFee(uint _total) internal returns (uint) {
    uint rake = feeCalc(_total);
    fantomDebtToRecipient += rake;
    uint leftover = _total - rake;
    return leftover;
  }

  function takeTokenFee(IERC20 _tokenToTake, uint _total) internal returns (uint) {
    uint rake = feeCalc(_total);
    TokenDebtToRecipient[_tokenToTake] += rake;
    uint leftover = _total - rake;
    return leftover;
  }

  function withdrawToken(IERC20 ERC20Address) public returns (bool) {
    require(msg.sender == treasury, "You are not the fee recipient");
    require(TokenDebtToRecipient[ERC20Address] > 0, "you have nothing to claim");

    uint payment = TokenDebtToRecipient[ERC20Address];
    TokenDebtToRecipient[ERC20Address] = 0;
    ERC20Address.transfer(treasury, payment);

    return true;
  }

  function withdrawFantom() public returns (bool) {
    require(msg.sender == treasury, "You are not the fee recipient");
    require(fantomDebtToRecipient > 0, "you have nothing to claim");

    uint payment = fantomDebtToRecipient;
    fantomDebtToRecipient = 0;
    payable(msg.sender).transfer(payment);

    return true;
  }

  function viewFantomCollected() public view returns (uint) {
    return fantomDebtToRecipient;
  }

  function viewTokensCollected(IERC20 _token) public view returns (uint) {
    return TokenDebtToRecipient[_token];
  }
}
