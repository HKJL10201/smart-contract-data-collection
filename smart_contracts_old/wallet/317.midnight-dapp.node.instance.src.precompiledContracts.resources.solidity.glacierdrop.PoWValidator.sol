pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
import "./PoWTargetCalculator.sol";

contract PoWValidator is PoWTargetCalculator {

    function validatePoW(
        address etcAddress,
        uint256 balance,
        uint64 powNonce,
        uint256 baseTarget,
        uint256 unlockingStartBlock,
        uint256 unlockingStopBlock
    ) view public returns(bool) {
        uint256 target = calculateTarget(balance, baseTarget, unlockingStartBlock, unlockingStopBlock);
        bytes memory message = abi.encodePacked(etcAddress, powNonce);
        bytes32 hash = keccak256(message);
        return uint256(hash) < target;
    }
}