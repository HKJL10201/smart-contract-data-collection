pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
library Constants {
  function constantsRepository() internal pure returns (address) { return address(20); }
  function tagsRepository() internal pure returns (address) { return address(21); }
  function proofOfBurnVerifier() internal pure returns (address) { return address(22); }
  function claimer() internal pure returns (address) { return address(23); }
  function duster() internal pure returns (address) { return address(24); }
  function erc20TokenStart() internal pure returns (address) { return address(25); }
  function glacierDropVerifier() internal pure returns (address) { return address(29); }
  function bech32AddressDecoder() internal pure returns (address) { return address(31); }

  uint constant bitcoinMainChainId = 0;

  uint constant bitcoinTestChainId = 1;

  uint constant ethereumMainChainId = 2;

  uint constant ethereumTestChainId = 3;

  function getBitcoinMainNetChainId() internal pure returns (uint) { return bitcoinMainChainId; }

  function getEthereumMainNetChainId() internal pure returns (uint) { return ethereumMainChainId; }

  function getBitcoinTestNetChainId() internal pure returns (uint) { return bitcoinTestChainId; }

  function getEthereumTestNetChainId() internal pure returns (uint) { return ethereumTestChainId; }
}