// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.12;

import "./UserOperation.sol";

/**
 * Aggregator Signature validator
 */
interface IAggregator {
  /**
   * validate aggregated signature
   * revert if the aggregated signature does not match the given list of operations.
   */

  function validateSignatures(
    UserOperation[] calldata userOps,
    bytes calldata signature
  ) external view;

  /**
   * validate signature of a single userOp
   * This method should be called by bundler after EntryPoint.simulateValidation() returns (reverts) with ValidationResultWithAggregation
   * @param userOp the userOperation received from the user.
   * @return sigForUserOp the value to put into the signature field of the userOp when calling handleOps.
   *         (usually empty, unless accoung and aggregator support some kine of "multisig")
   */
  function validateUserOpSignature(
    UserOperation calldata userOp
  ) external view returns (bytes memory sigForUserOp);

  /**
   * aggregate multiple signature to a single value.
   * This method is called off-chain to calulate the signature to pass handleOps()
   * bundler MAY use optimized custom code perform this aggregation
   * @param userOps array of UserOperations to collect the signatures from.
   * @return aggregatedSignature the aggregated signature
   */

  function aggregateSignature(
    UserOperation[] calldata userOps
  ) external view returns (bytes memory aggregatedSignature);
}
