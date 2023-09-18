// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Lotte.sol';

contract MockLotte is Lotte {
  constructor(
    address _token,
    address _vaultAddress,
    uint _ticketPrice,
    uint _minDrawDuration,
    uint _systemFeeRate,
    uint _drawFeeRate,
    uint _burnRate,
    uint _refRateLayer1,
    uint _refRateLayer2,
    uint _refRateLayer3
  )
    Lotte(
      _token,
      _vaultAddress,
      _ticketPrice,
      _minDrawDuration,
      _systemFeeRate,
      _drawFeeRate,
      _burnRate,
      _refRateLayer1,
      _refRateLayer2,
      _refRateLayer3
    )
  {}

  function getRandom() public pure override returns (uint) {
    return 11;
  }
}
