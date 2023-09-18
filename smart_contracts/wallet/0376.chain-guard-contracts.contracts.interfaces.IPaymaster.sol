pragma solidity ^0.8.12;

import "./UserOperation.sol";

/**
 * the interface exposed by a paymaster contract, who agrees to pay the gas for user's operation.
 * a paymaster must hold a stake to cover the required entrypoint stake and also the gas for the transaction.
 */
interface IPaymaster {
    enum PostOpMode {
        opSucceeded, // user op succeeded
        opReverted, // user op reverted, still has to pay for gas
        postOpReverted // user op succeeded, but cause postOp to rever
    }

    /**
     * payment validation: check if paymaster agrees to pay.
     * Must verify sender if the entryPoint
     * Revert to reject this request
     * Note that bundlers will reject this method if it changes the state, unless the paymaster is trusted (whitelisted)
     * The paymaster pre-pays using its deposit, and receive back a refund after the postOp method returns.
     * @param userOp the user operation
     * @param userOpHash hash of the user's request data
     * @param maxCost the maximum cost of this transaction (based on maximum gas and gas price from userOp)
     * @return context value to send to a postOp. Zero length to signify postOp is not required.
     * @return validationData signature and time-range of this operation, encode the same as the return of validateUserOperation
     */
    function validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) external returns (bytes memory context, uint256 validationData);

    /**
     * post-operation handler. Must verify sender is the EntryPoint
     * @param mode - enum with the above options
     * @param context - the context value returned by validatePaymasterUserOp
     * @param actualGasCost - actual gas used so far (without this postOp call)
     */
    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) external;
}
