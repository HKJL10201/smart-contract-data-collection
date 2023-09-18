// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '../poll/BasePollType.sol';

contract CumulativePollType is BasePollType {
  function getPollTypeName() external pure override returns (string memory) {
    return 'Cumulative';
  }
}
