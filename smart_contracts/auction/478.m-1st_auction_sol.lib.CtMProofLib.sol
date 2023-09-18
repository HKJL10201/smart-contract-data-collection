// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {UIntLib} from "./UIntLib.sol";
import {ECPoint, ECPointLib} from "./ECPointLib.sol";
import {Bidder, BidderList, BidderListLib} from "./BidderListLib.sol";
import {Ct, CtLib} from "./CtLib.sol";
import {SameDLProof, SameDLProofLib} from "./SameDLProofLib.sol";
import {DLProof, DLProofLib} from "./DLProofLib.sol";

struct CtMProof {
    SameDLProof pi;
}

library CtMProofLib {
    using UIntLib for uint256;
    using ECPointLib for ECPoint;
    using SameDLProofLib for SameDLProof;
    using DLProofLib for DLProof;

    function valid(
        CtMProof memory pi,
        Ct memory ct,
        ECPoint memory y,
        ECPoint memory zM
    ) internal view returns (bool) {
        return pi.pi.valid(ECPointLib.g(), y, ct.u, ct.c.sub(zM));
    }

    function valid(
        CtMProof[] memory pi,
        Ct[] memory ct,
        ECPoint memory y,
        ECPoint memory zM
    ) internal view returns (bool) {
        for (uint256 i = 0; i < pi.length; i++) {
            if (valid(pi[i], ct[i], y, zM) == false) return false;
        }
        return true;
    }
}
