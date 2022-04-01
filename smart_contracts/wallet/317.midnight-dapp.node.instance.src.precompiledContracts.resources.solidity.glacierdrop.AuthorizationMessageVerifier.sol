pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
import "../Constants.sol";
import "../utils/CallPrecompiledContract.sol";

contract AuthorizationMessageVerifier {

    /// Verifies that the ETC owner provided authorization for doing the drop to an specified midnight address
    /// The authorization is provided by signing the message:
    ///     "\x19Ethereum Signed Message:\n192I authorise DUST_RECEIVER_BECH32 to get my ETC_OWNER_HEX GlacierDrop")
    /// @param dustReceiverString midnight transparent address that will be receiving the dust from the drop, in bech32 format
    /// @param etcOwnerString ETC address that owned the ether, in hex format (prefixed by 0x)
    /// @param signatureV v part of the ETC authorization signature
    /// @param signatureR r part of the ETC authorization signature
    /// @param signatureS s part of the ETC authorization signature
    function verifyAuthorizationMessage(string memory dustReceiverString,
                                        string memory etcOwnerString,
                                        uint8 signatureV,
                                        bytes32 signatureR,
                                        bytes32 signatureS) public returns (address, address) {
        bytes memory authorizationMessage = abi.encodePacked("I authorise ", dustReceiverString, " to get my ", etcOwnerString, " GlacierDrop");

        // 129 is the length of the authorization message
        bytes memory messageToSign = abi.encodePacked("\x19Ethereum Signed Message:\n129", authorizationMessage);

        bytes32 msgHash = keccak256(messageToSign);
        address signer = ecrecover(msgHash, signatureV, signatureR, signatureS);

        address etcOwner = hexToAddress(etcOwnerString);

        address dustReceiver = bech32ToAddress(dustReceiverString);

        require(etcOwner == signer, "Invalid authorization signature");
        return (dustReceiver, etcOwner);
    }

    function hexToAddress(string memory hexAddressString) public pure returns (address) {
        bytes memory hexAddressBytes = bytes(hexAddressString);

        require(hexAddressBytes.length == 2 * 20 + 2, "Failed to decode ETC owner hex address: Invalid length");

        uint firstCharacter = uint8(hexAddressBytes[0]);
        uint secondCharacter = uint8(hexAddressBytes[1]);
        require(firstCharacter == 48 && secondCharacter == 120, "Failed to decode ETC owner hex address: No 0x prefix");

        uint result = 0;
        for (uint i = 2; i < hexAddressBytes.length; i++) {
            uint c = uint8(hexAddressBytes[i]);
            if (c >= 48 && c <= 57) { // Numbers
                result = result * 16 + (c - 48);
            } else if(c >= 65 && c<= 90) { // Characters in mayus
                result = result * 16 + (c - 55);
            } else if(c >= 97 && c<= 122) { // Characters in minus
                result = result * 16 + (c - 87);
            } else {
                require(false, "Failed to decode ETC owner hex address: Invalid hex character");
            }
        }
        return address(uint160(result));
    }

    function bech32ToAddress(string memory bech32AddressString) public returns (address) {
        address bech32DecoderAddress = Constants.bech32AddressDecoder();
        bytes memory encodedInputData = bytes(bech32AddressString);
        string memory errorMsg = "Failed to decode midnight bech32 address";

        bytes32 decodedAddress = CallPrecompiledContract.callPrecompiledContract(bech32DecoderAddress, encodedInputData, errorMsg);
        require(decodedAddress != bytes32(0), errorMsg);

        return address(uint160(uint256(decodedAddress)));
    }

}