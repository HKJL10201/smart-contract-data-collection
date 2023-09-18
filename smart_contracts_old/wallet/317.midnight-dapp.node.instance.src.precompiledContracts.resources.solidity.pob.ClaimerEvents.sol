pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
/// @title Group all events that can be emitted in Claimer.sol
contract ClaimerEvents {

  event Committed (
    address indexed prover,
    bytes32 burnTxHash,
    bytes32 proofHash,
    bytes32 commitHash
  );

  event Redeemed (
    address indexed prover,
    bytes32 burnTxHash,
    bytes32 proofHash,
    bytes32 commitHash,
    bool autoExchange
  );

}
