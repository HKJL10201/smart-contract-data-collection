// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "ds-test/test.sol";
import "./Hevm.sol";
import "./Console.sol";

contract BaseTest is DSTest {
    function sign(uint256 signerPrivateKey, bytes32 digest) internal returns (bytes memory) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = hevm.sign(signerPrivateKey, digest);

        bytes memory signature = "";

        // case 65: r,s,v signature (standard)
        assembly {
            // Logical shift left of the value
            mstore(add(signature, 0x20), r)
            mstore(add(signature, 0x40), s)
            mstore(add(signature, 0x60), shl(248, v))
            // 65 bytes long
            mstore(signature, 0x41)
            // Update free memory pointer
            mstore(0x40, add(signature, 0x80))
        }

        return signature;
    }

    Hevm public hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
}
