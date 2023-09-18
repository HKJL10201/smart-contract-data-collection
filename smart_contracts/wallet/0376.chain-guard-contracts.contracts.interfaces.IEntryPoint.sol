pragma solidity ^0.8.12;

import "./UserOperation.sol";
import "./IStakeManager.sol";
import "./IAggregator.sol";

interface IEntryPoint is IStakeManager {
  //=============================== Event ======================================

  /**
   * An event emitted after each successful request
   * @param userOpHash - unique identifier for the request
   * @param sender - the account that generates this request
   * @param paymaster - if non-null, the paymaster that pays for this request
   * @param nonce - value from the request
   * @param success - true if the sender transaction succeeded, false if reverted
   * @param actualGasCost - actual amount paid (by account or paymaster) for this UserOperation
   * @param actualGasUsed - total gas used by this UserOperation (including preVerification, creation, validation and execution)
   */
  event UserOperationEvent(
    bytes32 indexed userOpHash,
    address indexed sender,
    address indexed paymaster,
    uint256 nonce,
    bool success,
    uint256 actualGasCost,
    uint256 actualGasUsed
  );

  /**
   * account "sender" was deployed
   * @param userOpHash - the userOp that deployed this account. UserOperationEvent will follow.
   * @param sender - the account that is deployed
   * @param factory - the factory used to deploy this account
   * @param paymaster - the paymaster used by this UserOp
   */
  event AccountDeployed(
    bytes32 indexed userOpHash,
    address indexed sender,
    address factory,
    address paymaster
  );

  /**
   * An event emitted if the UserOperation "callData" reverted with non-zero length
   * @param userOpHash - the request unique identifier
   * @param sender - the sender of this request
   * @param nonce - the nonce used in the request
   * @param revertReason - the return bytes from the (reverted) call to "callData"
   */
  event UserOperationRevertReason(
    bytes32 indexed userOpHash,
    address indexed sender,
    uint256 nonce,
    bytes revertReason
  );

  /**
   * signature aggregator used by the following UserOperationEvents within this bundle.
   */
  event SignatureAggregatorChanged(address indexed aggregator);

  //=============================== Error ======================================

  /**
   * a custom revert error of handleOps, to identify the offending op.
   * NOTE: if simulateValidation passes successfully, there should be no reason fo handleOps to faild it.
   * @param opIndex - index into the array of ops to the failed one
   * @param reason - revert reason
   *                 The string start with a unique code "AAmn", where "m" = 1 for factory, 2 for account, 3 for paymaster issue
   */
  error FailedOp(uint256 opIndex, string reason);

  /**
   * error case when a signature aggregator fails to verify the aggregated signature it had created.
   */
  error SignatureValidationFailed(address aggregator);

  /**
   * successful result from simulateValidation.
   * @param returnInfo gas and time-range returned values
   * @param senderInfo stake information about the sender
   * @param factoryInfo stake information about the factory
   * @param paymasterInfo stake information about the paymaster
   */
  error ValidationResult(
    ReturnInfo returnInfo,
    StakeInfo senderInfo,
    StakeInfo factoryInfo,
    StakeInfo paymasterInfo
  );

  /**
   * successful result from simulateValidation, if the account returns a signature aggregator
   * @param returnInfo - gas and time-range returned values
   * @param senderInfo - stake information about the sender
   * @param factoryInfo - stake information about the factory
   * @param paymasterInfo - stake information about the paymaster
   * @param aggregatorInfo - signature aggregation info (if the account requires signature aggregator)
   *                         bundler MUST use it to verify the signature, or reject the UserOperation
   */
  error ValidationResultWithAggregation(
    ReturnInfo returnInfo,
    StakeInfo senderInfo,
    StakeInfo factoryInfo,
    StakeInfo paymasterInfo,
    AggregatorStakeInfo aggregatorInfo
  );

  /**
   * return value of getSenderAddress
   */
  error SenderAddressResult(address sender);

  /**
   * reuturn value of simulationHandleOp
   */
  error ExecutionResult(
    uint256 preOpGas,
    uint256 paid,
    uint48 validAfter,
    uint48 validUntil,
    bool targetSuccess,
    bytes targetResult
  );

  //=============================== Struct ======================================

  /**
   * gas and return values during simulation
   * @param prepOpGas - the gas used for validation (including preValidationGas)
   * @param prefund - the required prefund for this operation
   * @param sigFailed - validateUserOp(or paymaster)'s signature check failed
   * @param validAfter - first timestamp this UserOp is valid
   * @param validUntil - last timestamp this UserOp is valid
   * @param paymasterContext returned by validatePaymasterUserOp
   */
  struct ReturnInfo {
    uint256 preOpGas;
    uint256 prefund;
    bool sigFailed;
    uint48 validAfter;
    uint48 validUntil;
    bytes paymasterContext;
  }

  /**
   * return aggregated signature info
   * the aggregator reuturned by the account, and its current stake
   */
  struct AggregatorStakeInfo {
    address aggregator;
    StakeInfo stakeInfo;
  }

  // userOps handled, per aggregator
  struct UserOpsPerAggregator {
    UserOperation[] userOps;
    IAggregator aggregator;
    bytes signature;
  }

  //=============================== Function ======================================

  /**
   * Execute a batch of UserOperation.
   * No signature aggregator is used.
   * If any account requires an aggregator then handleAggregatorOps() must be used instead
   * @param ops - the operation to execute
   * @param beneficiary - the address to receive fees
   */
  function handleOps(
    UserOperation[] calldata ops,
    address payable beneficiary
  ) external;

  /**
   * Execute a batch of UserOperation with Aggregators
   * @param opsPerAggregator - the operations to execute, grouped by aggregator (or address(0) for no-aggregator accounts)
   * @param beneficiary - the address to receive the fees
   */
  function handleAggregatedOps(
    UserOpsPerAggregator[] calldata opsPerAggregator,
    address payable beneficiary
  ) external;

  /**
   * generate a request Id - an unique identifier for this request.
   * the request ID is a hash over the content of the userOp, the entryPoint and the chainId
   */
  function getUserOpHash(
    UserOperation calldata userOp
  ) external view returns (bytes32);

  /**
   * simulate a call to account.validateUserOp and paymaster.validatePaymasterUserOp.
   * @dev this method always revert. Successful result is ValidationResult error, other errors are failures.
   * @dev the node must also verify it doesn't use banned opcodes, and that it doesn't reference storage outside the account's data
   * @param userOp the user operation to validate.
   */
  function simulateValidation(UserOperation calldata userOp) external;

  /**
   * get counterfactual sender address.
   * Calculate the sender contract address that will be generated by the initCode and salt in the UserOperation.
   * this method always revert, and return the address in SenderAaddressResult error
   * @param initCode - the constructor code to be passed into the UserOperation.
   */
  function getSenderAddress(bytes memory initCode) external;

  /**
   * simulate full execution of a UserOperation (including both validation and target execution)
   * this method will always revert with "Execution Result"
   * it performs full validation of the UserOperation, but ignores signature error.
   * an optional target address is called after userop succeeds, and its value is returned
   * Note that in order to collect the success/failure of the target call, it must be executed with trace enabled to taracthe emitted events
   * @param op - the UserOperation to simulate
   * @param target - target if nonzero, a target address to call after userop simulation. If called, the targetSuccess and targetResult
   *                 are set to the return from that call.
   * @param targetCallData - callData to pass to target address
   */
  function simulateHandleOp(
    UserOperation calldata op,
    address target,
    bytes calldata targetCallData
  ) external;
}
