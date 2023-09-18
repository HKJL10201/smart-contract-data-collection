// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IVerifier} from "../../../interfaces/IVerifier.sol";
import {SemaphoreCoreBaseInternal} from "./SemaphoreCoreBaseInternal.sol";

contract SemaphoreCoreBaseMock is SemaphoreCoreBaseInternal {
     function ___verifyProof(
        bytes32 signal,
        uint256 root,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof,
        IVerifier verifier
    ) external view {
        _verifyProof(signal, root, nullifierHash, externalNullifier, proof, verifier);
    }
}