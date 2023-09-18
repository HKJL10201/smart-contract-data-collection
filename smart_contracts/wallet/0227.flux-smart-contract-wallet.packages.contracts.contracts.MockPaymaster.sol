// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@account-abstraction/contracts/core/BasePaymaster.sol";

contract MockPaymaster is BasePaymaster {
    constructor(IEntryPoint anEntryPoint) BasePaymaster(anEntryPoint) {}

    function validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 requestId,
        uint256 maxCost
    ) external virtual override returns (bytes memory context) {
        return abi.encode();
    }

    function _postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) internal override {}
}
