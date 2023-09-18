// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./interfaces/IPayment.sol";

contract Payment is IPayment, Ownable {
  mapping(address => bool) public supported_tokens;
  mapping(address => uint256) public account_nonce;

  // That would be better to have more than one validators
  // Needs to be updated later for more validation
  address public validator;
  address public pendingValidator;

  event TokenSupport(address indexed token, bool supported);
  event Deposited(address indexed user, address token, uint256 amount);
  event Paid(
    address indexed user,
    address token,
    uint256 amount,
    address indexed validator,
    uint256 nonce
  );
  event ValidatorSet(address indexed validator);

  constructor() {}

  /**
   * @dev Adds the token to the supported , removes the token from the supported
   * @param token - The token address you wanna make supported/unsupported
   * @param supported - true => supported, false => unsupported
   */
  function support(address token, bool supported) external onlyOwner {
    require(supported_tokens[token] != supported, "no status update");
    supported_tokens[token] = supported;
    emit TokenSupport(token, supported);
  }

  /**
   * @dev Allows the specific address as a validator, it can only work once the address accept the request
   * @param _validator - The validator address
   */
  function setValidator(address _validator) external onlyOwner {
    pendingValidator = _validator;
  }

  /**
   * @dev Accepts the validator pending request
   */
  function accept() external {
    require(pendingValidator == msg.sender, "not a pending validator");
    validator = pendingValidator;
    pendingValidator = address(0);
    emit ValidatorSet(validator);
  }

  /**
   * @dev Deposits the token to the contracts.
   * @param token - The token address you're gonna deposit
   * @param amount - The deposit amount
   */
  function deposit(address token, uint256 amount) external override {
    require(supported_tokens[token], "not supported");
    uint256 beforeBal = IERC20(token).balanceOf(address(this));
    require(
      IERC20(token).transferFrom(msg.sender, address(this), amount),
      "deposit failed!"
    );
    uint256 afterBal = IERC20(token).balanceOf(address(this));
    uint256 depositedAmt = afterBal - beforeBal;
    emit Deposited(msg.sender, token, depositedAmt);
  }

  /**
   * @dev Sends the funds to the user
   */
  function pay(PayParams calldata params) external override {
    require(params.validator == validator, "not whitelisted");
    require(supported_tokens[params.token], "not supported");
    uint256 nonce = account_nonce[params.to] + 1;
    bytes32 validatorHash = keccak256(abi.encode(params.to, nonce));
    require(
      params.validator == _recoverSignature(validatorHash, params.signature),
      "invalid signature"
    );
    require(
      IERC20(params.token).balanceOf(address(this)) >= params.amount,
      "insufficient balance"
    );

    IERC20(params.token).transfer(params.to, params.amount);
    account_nonce[params.to] = nonce;

    emit Paid(params.to, params.token, params.amount, params.validator, nonce);
  }

  function _recoverSignature(bytes32 _signed, bytes calldata _sig)
    internal
    pure
    returns (address)
  {
    return ECDSA.recover(ECDSA.toEthSignedMessageHash(_signed), _sig);
  }
}
