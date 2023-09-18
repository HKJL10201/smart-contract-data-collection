// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./verifier.sol" as verifier;
import "./Structures.sol";

/// @dev Extract proof object from input.
/// @param input Input struct.
/// @return Proof Proof object.
function createProof(Input memory input)
    pure
    returns (verifier.Verifier.Proof memory)
{
    return
        verifier.Verifier.Proof(
            verifier.Pairing.G1Point(input.a[0], input.a[1]),
            verifier.Pairing.G2Point(input.b[0], input.b[1]),
            verifier.Pairing.G1Point(input.c[0], input.c[1])
        );
}

/// @dev transforms input to structure and calculates difficulty.
/// @param input Input in array of nums.
/// @return Output Output object.
function parseInput(uint256[8] memory input) pure returns (Output memory) {
    // last values in first header
    uint256 prevHash = input[6];
    uint256 lastHash = input[5];
    // shift and mask
    // FFFF001D
    uint256 bits = ((input[4] >> 32) &
        0x00000000000000000000000000000000000000000000000000000000FFFFFFFF);

    // last 2 bytes
    // 1D
    uint256 head = bits &
        0x00000000000000000000000000000000000000000000000000000000000000FF;

    // last 6 bytes
    // FFFF00
    uint256 tail = (bits >> 8);
    uint256 tail0 = tail &
        0x00000000000000000000000000000000000000000000000000000000000000FF;
    // 00
    tail0 = tail0 << 16;
    // FF00
    uint256 tail1 = tail &
        0x000000000000000000000000000000000000000000000000000000000000FF00;
    // FF
    uint256 tail2 = tail &
        0x0000000000000000000000000000000000000000000000000000000000FF0000;
    tail2 = tail2 >> 16;
    // swap endianness
    tail = tail0 + tail1 + tail2;
    // get target
    uint256 target = tail * 2**(8 * (head - 3));
    // get difficulty
    uint256 difficulty = 0x00000000FFFF0000000000000000000000000000000000000000000000000000 / target;
    return Output(prevHash, lastHash, 0, difficulty);
}
