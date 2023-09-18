// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {UIntLib} from "./UIntLib.sol";
import {ECPoint, ECPointLib} from "./ECPointLib.sol";
import {Ct, CtLib} from "./CtLib.sol";

struct SameDLProof {
    ECPoint grr1;
    ECPoint grr2;
    uint256 rrr;
}

library SameDLProofLib {
    using UIntLib for uint256;
    using ECPointLib for ECPoint;

    function valid(
        SameDLProof memory pi,
        ECPoint memory g1,
        ECPoint memory g2,
        ECPoint memory y1,
        ECPoint memory y2
    ) internal view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                g1.pack(),
                g2.pack(),
                y1.pack(),
                y2.pack(),
                pi.grr1.pack(),
                pi.grr2.pack()
            )
        );
        uint256 c = uint256(digest).modQ();
        return
            g1.scalar(pi.rrr).equals(pi.grr1.add(y1.scalar(c))) &&
            g2.scalar(pi.rrr).equals(pi.grr2.add(y2.scalar(c)));
    }

    function valid(
        SameDLProof[] memory pi,
        ECPoint[] memory g1,
        ECPoint[] memory g2,
        ECPoint[] memory y1,
        ECPoint[] memory y2
    ) internal view returns (bool) {
        for (uint256 i = 0; i < pi.length; i++) {
            if (valid(pi[i], g1[i], g2[i], y1[i], y2[i]) == false) return false;
        }
        return true;
    }
}
