pragma solidity ^0.8.12;
import "./UserOperation.sol";

interface IAccount {
    /**
     * Validate user's signature and nonce
     * the entryPoint will make the call to the recipient only if this validation call returns successfully
     * signature failure should be reported by returning SIG_VALIDATION_FAIL
     * This allows making a "simulation call" without a valid signature
     * Other failures (e.g nonce mismatch, or invalid signature format) should still revert to signal failure.
     *
     * @dev Must validate caller is the entryPoint.
     *      Must validate the signature and nonce.
     * @param userOp the operation that is about to be executed.
     * @param userOpHash hash of the user's request data. can be used as the basis for signature.
     * @param missingAccountFunds missing funds on the account's deposit in the entryPoint.
     *                            This is the minimum amount to transfer the sender(entryPoint) to be able to make the call.
     *                            The excess is left as a deposit in the entryPoint, for future calls.
     *                            Can be withdrawn anytime using "entryPoint.withdrawTo()"
     *                            In case there is a paymaster in the request (or the current deposit is high enough), this value will be zero.
     * @return validationData packaged ValidationData structure. use `_packValidationData` and `_unpackValidationDat` to encode and decode
     *        <20-byte> sigAuthorizer - 0 for valid signature, 1 to mark signature failure, otherwise, an address of an "authorizer" contract
     *        <6-byte> validateUntil - last timestamp this operation is valid. 0 for no expiration
     *        <6-byte> validateAfter - first timestamp this operation is valid
     *        If an account doesn't use time-range, it is enough to return SIG_VALIDATION_FAILED value for signature failure.
     *        Note that the validation code cannot use block.timestamp or any this similar directly.
     */
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external returns (uint256 validationData);

    function changeOwner(address newOwner) external;
}
