// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/**
 * @dev The parameters used to pay the specific amount of token to the user
 * @param token - The payment token address
 * @param to - The receiver address
 * @param amount - The token amount
 * @param validators - The validator address who validates the payment amount, token and the receiver.
 * @param signatures - The sign messages of the validator to verify the transaction
 */
struct PayParams {
  address token;
  address to;
  uint256 amount;
  address validator;
  bytes signature;
}

interface IPayment {
  function deposit(address token, uint256 amount) external;

  function pay(PayParams calldata params) external;
}
