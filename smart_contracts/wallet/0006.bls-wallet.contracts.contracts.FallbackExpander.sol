//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

import "./AddressRegistry.sol";
import "./BLSPublicKeyRegistry.sol";
import "./AggregatorUtilities.sol";
import "./lib/RegIndex.sol";
import "./lib/VLQ.sol";
import "./lib/PseudoFloat.sol";
import "./interfaces/IExpander.sol";
import "./interfaces/IWallet.sol";

/**
 * An expander that supports any operation.
 *
 * This is still a more compact encoding due to the use of VLQ and general byte
 * packing in several places where the solidity abi would just use a 32-byte
 * word.
 *
 * Example:
 *
 * 0x
 * 2409925687d52a67b435a011cf9ec82d390300cd12e5842d2a0c5e1c27898551 // BLS key
 * 0c4a8cbcc96cada40301e1d2a2d68425b5cf0e18f5cb12fa272f841017c36776 // BLS key
 * 27b9f42b237d75bcb0473e2eada290e62ec77048187484f8952fffe0239f7ba9 // BLS key
 * 24f1fc8a1f7256dc2914e524966309df2226fd329373aaaae1881bf5cd0c62f4 // BLS key
 *
 * 00 // nonce: 0
 * 3100 // gas: 100,000
 * 02 // two actions
 *
 * // Action 1
 * 7b0f // ethValue: 12300000000000000 (0.0123 ETH)
 * 70997970c51812dc3a010c7d01b50e0d17dc79c8 // contractAddress
 * 00 // encodedFunction: (empty)
 *
 * // Action 2
 * 6c01 // ethValue: 12000000000000 (0.000012 ETH)
 * 4bd2e4e99b50a2a9e6b9dabfa3c8dcd1f885f008 // contractAddress (AggUtils)
 * 04 // 4 bytes for encodedFunction
 * 1dfea6a0 // sendEthToTxOrigin
 *
 * The proposal doc for the new expander lists the same example ("Example of an
 * Expanded User Operation" https://hackmd.io/0q7H3Ad0Su-I4RWWK8wQPA) using the
 * solidity ABI, which uses 608 bytes. Here we've encoded the same thing (plus
 * gas) in 182 bytes, which is 70% smaller. (If you account for the zero-byte
 * discount, the saving is still over 30%.)
 */
contract FallbackExpander is IExpander {
    BLSPublicKeyRegistry public blsPublicKeyRegistry;
    AddressRegistry public addressRegistry;
    AggregatorUtilities public aggregatorUtilities;

    constructor(
        BLSPublicKeyRegistry blsPublicKeyRegistryParam,
        AddressRegistry addressRegistryParam,
        AggregatorUtilities aggregatorUtilitiesParam
    ) {
        blsPublicKeyRegistry = blsPublicKeyRegistryParam;
        addressRegistry = addressRegistryParam;
        aggregatorUtilities = aggregatorUtilitiesParam;
    }

    function expand(bytes calldata stream) external view returns (
        uint256[4] memory senderPublicKey,
        IWallet.Operation memory operation,
        uint256 bytesRead
    ) {
        uint256 originalStreamLen = stream.length;
        uint256 decodedValue;
        bool decodedBit;
        uint256 bitStream;

        (bitStream, stream) = VLQ.decode(stream);

        (decodedBit, bitStream) = decodeBit(
            bitStream
        );

        if (decodedBit) {
            (decodedValue, stream) = RegIndex.decode(stream);
            senderPublicKey = blsPublicKeyRegistry.lookup(decodedValue);
        } else {
            senderPublicKey = abi.decode(stream[:128], (uint256[4]));
            stream = stream[128:];
        }

        (decodedValue, stream) = VLQ.decode(stream);
        operation.nonce = decodedValue;

        (decodedValue, stream) = PseudoFloat.decode(stream);
        operation.gas = decodedValue;

        uint256 actionLen;
        (actionLen, stream) = VLQ.decode(stream);
        operation.actions = new IWallet.ActionData[](actionLen);

        // hasTxOriginPayment
        (decodedBit, bitStream) = decodeBit(bitStream);

        if (decodedBit) {
            // We would use a separate variable for this, but the solidity
            // compiler makes it important to minimize local variables.
            actionLen -= 1;
        }

        for (uint256 i = 0; i < actionLen; i++) {
            uint256 ethValue;
            (ethValue, stream) = PseudoFloat.decode(stream);

            address contractAddress;

            (decodedBit, bitStream) = decodeBit(bitStream);

            if (decodedBit) {
                (decodedValue, stream) = RegIndex.decode(stream);
                contractAddress = addressRegistry.lookup(decodedValue);
            } else {
                contractAddress = address(bytes20(stream[:20]));
                stream = stream[20:];
            }

            (decodedValue, stream) = VLQ.decode(stream);
            bytes memory encodedFunction = stream[:decodedValue];
            stream = stream[decodedValue:];

            operation.actions[i] = IWallet.ActionData({
                ethValue: ethValue,
                contractAddress: contractAddress,
                encodedFunction: encodedFunction
            });
        }

        if (actionLen < operation.actions.length) {
            (decodedValue, stream) = PseudoFloat.decode(stream);

            operation.actions[actionLen] = IWallet.ActionData({
                ethValue: decodedValue,
                contractAddress: address(aggregatorUtilities),
                encodedFunction: abi.encodeWithSignature("sendEthToTxOrigin()")
            });
        }

        bytesRead = originalStreamLen - stream.length;
    }

    function decodeBit(uint256 bitStream) internal pure returns (bool, uint256) {
        return ((bitStream & 1) == 1, bitStream >> 1);
    }
}
