pragma solidity ^0.4.15;

import "./MiniMeIrrVesDivToken.sol";

/**
 * Copyright 2017, Konstantin Viktorov (XRED Foundation)
 **/

contract XREDCoin is MiniMeIrrVesDivToken {
  // @dev XREDCoin constructor just parametrizes the MiniMeIrrVesDivToken constructor
  function XREDCoin(
    address _tokenFactory
  ) MiniMeIrrVesDivToken(
    _tokenFactory,
    0x0,                    // no parent token
    0,                      // no snapshot block number from parent
    "XRED token",           // Token name
    18,                     // Decimals
    "XRED",                 // Symbol
    true                    // Enable transfers
    ) {}
}
