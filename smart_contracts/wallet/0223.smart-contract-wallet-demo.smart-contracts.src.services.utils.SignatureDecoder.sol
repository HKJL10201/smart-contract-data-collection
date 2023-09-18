// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "openzeppelin-contracts/utils/cryptography/ECDSA.sol";

/// @title SignatureDecoder - Decodes signatures that a encoded as bytes
/// @author Richard Meissner - <richard@gnosis.pm>
contract SignatureDecoder {
    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to peform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }

    /**
    * @dev Gets signers from the signature and the passed in datahash.
    * @notice Make sure to check the datahash is correct, to avoid malleability attacks.
    * @param dataHash bytes32 hash of the data.
    * @param signatures concatenated rsv signatures.
    * @param requiredSignatures number of required signatures.
    * @return address[] memory of signers.
    */
    function getSigners(
        bytes32 dataHash,
        bytes memory signatures,
        uint256 requiredSignatures
    ) public pure returns (address[] memory) {
        require(signatures.length / 65 == requiredSignatures, "Invalid signatures length");
        require(requiredSignatures > 0, "There must be more than 0 signatures");
        address[] memory signers;
        for (uint256 i = 0; i < requiredSignatures; i++) {
            (uint8 v, bytes32 r, bytes32 s) = signatureSplit(signatures, i);
            signers[i] = (ECDSA.recover(dataHash, v, r, s));
        }
        return signers;
    }
}