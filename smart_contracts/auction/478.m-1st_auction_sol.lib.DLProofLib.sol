// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {UIntLib} from "./UIntLib.sol";
import {ECPoint, ECPointLib} from "./ECPointLib.sol";

struct DLProof {
    ECPoint grr;
    uint256 rrr;
}

library DLProofLib {
    using UIntLib for uint256;
    using ECPointLib for ECPoint;

    function valid(
        DLProof memory pi,
        ECPoint memory g,
        ECPoint memory y
    ) internal view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(g.pack(), y.pack(), pi.grr.pack())
        );
        uint256 c = uint256(digest).modQ();
        return g.scalar(pi.rrr).equals(pi.grr.add(y.scalar(c)));
    }
}
