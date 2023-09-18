// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {UIntLib} from "./UIntLib.sol";
import {ECPoint, ECPointLib} from "./ECPointLib.sol";
import {Bidder, BidderList, BidderListLib} from "./BidderListLib.sol";
import {Ct, CtLib} from "./CtLib.sol";

struct Ct01Proof {
    ECPoint aa0;
    ECPoint aa1;
    ECPoint bb0;
    ECPoint bb1;
    uint256 c0;
    uint256 c1;
    uint256 rrr0;
    uint256 rrr1;
}

library Ct01ProofLib {
    using UIntLib for uint256;
    using ECPointLib for ECPoint;

    function valid(
        Ct01Proof memory pi,
        Ct memory ct,
        ECPoint memory y
    ) internal view returns (bool) {
        require(
            ECPointLib.g().scalar(pi.rrr0).equals(
                pi.aa0.add(ct.u.scalar(pi.c0))
            ),
            "Ct01Proof 1"
        );
        ECPoint memory s3L = y.scalar(pi.rrr0);
        ECPoint memory s3R = pi.bb0.add(ct.c.scalar(pi.c0));
        ECPoint memory s4L = y.scalar(pi.rrr1);
        ECPoint memory s4R = pi.bb1.add(ct.c.subZ().scalar(pi.c1));
        if (
            ECPointLib.g().scalar(pi.rrr0).equals(
                pi.aa0.add(ct.u.scalar(pi.c0))
            ) ==
            false ||
            ECPointLib.g().scalar(pi.rrr1).equals(
                pi.aa1.add(ct.u.scalar(pi.c1))
            ) ==
            false ||
            s3L.equals(s3R) == false ||
            s4L.equals(s4R) == false
        ) {
            return false;
        }

        bytes32 digest = keccak256(
            abi.encodePacked(
                y.pack(),
                ct.u.pack(),
                ct.c.pack(),
                pi.aa0.pack(),
                pi.bb0.pack(),
                pi.aa1.pack(),
                pi.bb1.pack()
            )
        );
        uint256 c = uint256(digest);
        unchecked {
            return pi.c0 + pi.c1 == c;
        }
    }

    function valid(
        Ct01Proof[] memory pi,
        Ct[] memory ct,
        ECPoint memory y
    ) internal view returns (bool) {
        for (uint256 i = 0; i < pi.length; i++) {
            if (valid(pi[i], ct[i], y) == false) return false;
        }
        return true;
    }
}
