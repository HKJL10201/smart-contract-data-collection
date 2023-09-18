// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library SignatureVerifier {
    using ECDSA for bytes32;

    function verifySignature(
        bytes32 _messageHash,
        bytes memory _signature,
        address _signer
    ) internal pure returns (bool) {
        bytes32 ethSignedMessageHash = _messageHash.toEthSignedMessageHash();
        address recoveredSigner = ethSignedMessageHash.recover(_signature);
        return recoveredSigner == _signer;
    }
}
