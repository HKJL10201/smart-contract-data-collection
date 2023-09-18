// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {ECPoint, ECPointLib} from "./lib/ECPointLib.sol";
import {Bidder, BidderList, BidderListLib} from "./lib/BidderListLib.sol";
import {Ct, CtLib} from "./lib/CtLib.sol";
import {Ct01Proof, Ct01ProofLib} from "./lib/Ct01ProofLib.sol";
import {CtMProof, CtMProofLib} from "./lib/CtMProofLib.sol";
import {DLProof, DLProofLib} from "./lib/DLProofLib.sol";
import {SameDLProof, SameDLProofLib} from "./lib/SameDLProofLib.sol";
import {Timer, TimerLib} from "./lib/TimerLib.sol";

contract Auction {
    using ECPointLib for ECPoint;
    using BidderListLib for BidderList;
    using CtLib for Ct;
    using CtLib for Ct[];
    using DLProofLib for DLProof;
    using DLProofLib for DLProof[];
    using Ct01ProofLib for Ct01Proof;
    using Ct01ProofLib for Ct01Proof[];
    using CtMProofLib for CtMProof;
    using CtMProofLib for CtMProof[];
    using SameDLProofLib for SameDLProof;
    using SameDLProofLib for SameDLProof[];
    using TimerLib for Timer;

    address sellerAddr;
    BidderList bList;
    ECPoint public pk;
    uint256 public M;
    uint256 public L;
    uint256[5] successCount;
    uint256 public minimumStake;
    bool public auctionAborted;
    Timer[5] public timer;
    uint64 public phase;
    uint256[] public m1stPrice;
    ECPoint[] public zM;

    uint256 public roundJ;
    uint256 public phase3ZkAndCount;
    uint256 public phase3MixCount;
    uint256 public phase3MatchCount;

    Ct public WSTotal;
    Ct[] public WSTotalzM;
    Ct[] public mixedWS;

    function test(uint256 i) public view returns (Ct memory) {
        return bList.get(i).C;
    }

    constructor(
        uint256 _M,
        uint256 _L,
        uint256[5] memory _timeout,
        uint256 _minimumStake
    ) {
        sellerAddr = msg.sender;
        require(_M > 0, "M <= 0");
        M = _M;
        require(_L > 1, "L <= 1");
        L = _L;
        require(
            _timeout.length == timer.length,
            "timeout.length != timer.length"
        );
        for (uint256 i = 0; i < _timeout.length; i++) {
            require(_timeout[i] > 0, "_timeout[i] <= 0");
            timer[i].timeout = _timeout[i];
        }
        timer[1].start = block.timestamp;
        timer[2].start = timer[1].start + timer[1].timeout;
        minimumStake = _minimumStake;
        phase = 1;

        zM.push(ECPointLib.identityElement());
        for (uint256 k = 1; k <= _M; k++) {
            zM.push(zM[k - 1].add(ECPointLib.z()));
        }
        for (uint256 j = 0; j < L; j++) {
            m1stPrice.push(0);
        }
    }

    function phase1BidderInit(
        ECPoint memory _pk,
        DLProof memory _pi
    ) public payable {
        require(phase == 1, "phase != 1");
        require(timer[1].exceeded() == false, "timer[1].exceeded() == true");
        require(_pk.isIdentityElement() == false, "pk must not be zero");
        require(_pi.valid(ECPointLib.g(), _pk), "Discrete log proof invalid.");
        require(
            msg.value >= minimumStake,
            "Bidder's deposit must larger than minimumStake."
        );
        bList.init(msg.sender, msg.value, _pk);
        pk = pk.add(_pk);
    }

    function phase1Success() public view returns (bool) {
        return bList.length() > M && timer[1].exceeded();
    }

    function phase2BidderSubmitBid(
        Ct[] memory _V,
        Ct01Proof[] memory _V_01_proof,
        Ct memory _C,
        CtMProof memory _C_proof,
        Ct memory _W,
        CtMProof memory _W_proof
    ) public {
        if (phase == 1 && phase1Success()) phase = 2;
        require(phase == 2, "phase != 2");
        require(timer[2].exceeded() == false, "timer[2].exceeded() == true");
        Bidder storage bidder = bList.find(msg.sender);
        require(
            bidder.addr != address(0),
            "Bidder can only submit their bids if they join in phase 1."
        );
        require(
            _V.length == L && _V_01_proof.length == L,
            "bid.length != L || pi01.length != L"
        );
        require(_V_01_proof.valid(_V, pk), "Ct01Proof not valid.");

        require(bidder.V.length == 0, "Already submit bid.");
        bidder.V = _V;
        require(_C_proof.valid(_C, pk, zM[1]), "_C_proof not valid.");
        bidder.C = _C;
        require(_W_proof.valid(_W, pk, zM[0]), "_W_proof not valid.");
        bidder.W = _W;

        successCount[2]++;
        if (phase2Success()) {
            roundJ = L - 1;
            phase = 3;
            timer[3].start = block.timestamp;
        }
    }

    function phase2Success() public view returns (bool) {
        return successCount[2] == bList.length();
    }

    function phase3ZkAnd(
        Ct memory _S,
        Ct01Proof memory _piC3,
        Ct01Proof memory _piC4
    ) public {
        require(phase == 3, "phase != 3");
        require(phase3ZkAndSuccess() == false, "phase3ZkAndSuccess()");
        require(timer[3].exceeded() == false, "timer[3].exceeded() == true");
        Bidder storage bidder = bList.find(msg.sender);
        require(bidder.hasSubmitZkAnd == false);

        if (roundJ <= L - 2) {
            if (m1stPrice[roundJ + 1] == 0) {
                bidder.C = bidder.C.sub(bidder.S);
                bidder.W = bidder.W.add(bidder.S);
            } else {
                bidder.C = bidder.S;
            }
        }

        require(_piC3.valid(_S, pk), "_piC3 not valid.");
        Ct memory c4 = bidder.C.add(bidder.V[roundJ]).sub(_S.add(_S));
        require(_piC4.valid(c4, pk), "_piC4 not valid.");
        bidder.S = _S;
        WSTotal = WSTotal.add(bidder.W.add(bidder.S));

        bidder.hasSubmitZkAnd = true;
        phase3ZkAndCount++;

        bidder.hasSubmitMixedWS = false;

        if (phase3ZkAndSuccess()) {
            phase3MixCount = 0;
            for (uint256 k = 0; k <= M; k++) {
                if (WSTotalzM.length <= k) WSTotalzM.push(WSTotal);
                else WSTotalzM[k] = WSTotal;
                if (k > 0) {
                    WSTotalzM[k] = WSTotalzM[k].subC(zM[k]);
                }
            }
            delete WSTotal;
            timer[3].start = block.timestamp;
        }
    }

    function phase3ZkAndSuccess() public view returns (bool) {
        return phase3ZkAndCount == bList.length();
    }

    function phase3Mix(Ct[] memory _mixedWS, SameDLProof[] memory _pi) public {
        require(phase == 3, "phase != 3");
        require(phase3ZkAndSuccess(), "phase3ZkAndSuccess()");
        require(phase3MixSuccess() == false, "phase3MixSuccess()");
        require(timer[3].exceeded() == false, "timer[3].exceeded()");
        Bidder storage bidder = bList.find(msg.sender);
        require(bidder.hasSubmitMixedWS == false, "bidder.hasSubmitMixedWS");

        require(_mixedWS.length == M + 1, "_mixedWS.length != M + 1");
        require(_pi.length == M + 1, "_pi.length != M + 1");

        for (uint256 k = 0; k <= M; k++) {
            require(
                _pi[k].valid(
                    WSTotalzM[k].u,
                    WSTotalzM[k].c,
                    _mixedWS[k].u,
                    _mixedWS[k].c
                ),
                "_pi[k]"
            );
        }

        if (mixedWS.length == 0) mixedWS.set(_mixedWS);
        else mixedWS.set(mixedWS.add(_mixedWS));

        bidder.hasSubmitMixedWS = true;
        phase3MixCount++;

        bidder.hasDecMixedWS = false;

        if (phase3MixSuccess()) {
            phase3MatchCount = 0;
            timer[3].start = block.timestamp;
        }
    }

    function phase3MixSuccess() public view returns (bool) {
        return phase3MixCount == bList.length();
    }

    function phase3Match(
        ECPoint[] memory _ux,
        SameDLProof[] memory _pi
    ) public {
        require(phase == 3, "phase != 3");
        require(phase3MixSuccess(), "phase3MixSuccess()");
        require(phase3MatchSuccess() == false, "phase3MatchSuccess()");
        require(timer[3].exceeded() == false, "timer[3].exceeded()");
        Bidder storage bidder = bList.find(msg.sender);
        require(bidder.hasDecMixedWS == false, "bidder.hasDecMixedC");

        require(_ux.length == M + 1, "_ux.length != M + 1");
        require(_pi.length == M + 1, "_pi.length != M + 1");

        for (uint256 k = 0; k <= M; k++) {
            mixedWS[k] = mixedWS[k].decrypt(bidder, _ux[k], _pi[k]);
        }

        bidder.hasDecMixedWS = true;
        phase3MatchCount++;

        if (roundJ > 0) {
            bidder.hasSubmitZkAnd = false;
        }

        if (phase3MatchSuccess()) {
            m1stPrice[roundJ] = 1;
            for (uint256 k = 0; k <= M; k++) {
                if (mixedWS[k].c.isIdentityElement()) {
                    m1stPrice[roundJ] = 0;
                    break;
                }
            }
            if (roundJ > 0) {
                phase3ZkAndCount = 0;
                for (uint256 k = 0; k <= M; k++) {
                    delete mixedWS[k];
                }
                roundJ--;
                timer[3].start = block.timestamp;
            } else {
                phase = 4;
                timer[4].start = block.timestamp;
            }
        }
    }

    function phase3MatchSuccess() public view returns (bool) {
        return phase3MatchCount == bList.length();
    }

    function phase4WinnerDecision(CtMProof memory _piM) public {
        require(phase == 4, "phase != 4");
        require(timer[4].exceeded() == false, "timer[4].exceeded() == true");
        Bidder storage bidder = bList.find(msg.sender);
        require(bidder.win == false, "Bidder has already declare win.");
        if (m1stPrice[roundJ] == 0) {
            bidder.W = bidder.W.add(bidder.S);
        }
        require(_piM.valid(bidder.W, pk, zM[1]), "CtMProof not valid.");
        bidder.win = true;
        successCount[4]++;
        if (phase4Success()) returnAllStake();
    }

    function phase4Success() public view returns (bool) {
        return successCount[4] == M;
    }

    function resolveAndReturnStake() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(timer[phase].exceeded(), "timer[].exceeded() == false");
        if (phase == 1) {
            require(phase1Success() == false, "phase1Success() == true");
        } else if (phase == 2) {
            require(phase2Success() == false, "phase2Success() == true");
            for (uint256 i = 0; i < bList.length(); i++) {
                if (bList.get(i).V.length != L) {
                    bList.get(i).isMalicious = true;
                }
            }
        } else if (phase == 3) {
            if (phase3MixSuccess() == false) {
                for (uint256 i = 0; i < bList.length(); i++) {
                    if (bList.get(i).hasSubmitMixedWS == false) {
                        bList.get(i).isMalicious = true;
                    }
                }
            } else if (phase3ZkAndSuccess() == false) {
                for (uint256 i = 0; i < bList.length(); i++) {
                    if (bList.get(i).hasSubmitZkAnd == false) {
                        bList.get(i).isMalicious = true;
                    }
                }
            } else if (phase3MatchSuccess() == false) {
                for (uint256 i = 0; i < bList.length(); i++) {
                    if (bList.get(i).hasDecMixedWS == false) {
                        bList.get(i).isMalicious = true;
                    }
                }
            } else revert("cannot resolve");
        } else if (phase == 4) {
            require(phase4Success() == false, "phase4Success() == true");
            require(successCount[4] == 0, "There are still some winners.");
        } else revert("phase out of range");
        returnAllStake();
        auctionAborted = true;
    }

    function returnAllStake() internal {
        uint256 compensation = 0;
        uint256 maliciousBidderCount = 0;
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).isMalicious) {
                compensation += bList.get(i).stake;
                bList.get(i).stake = 0;
                maliciousBidderCount++;
            }
        }
        compensation /= bList.length() - maliciousBidderCount;
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).isMalicious == false) {
                payable(bList.get(i).addr).transfer(
                    bList.get(i).stake + compensation
                );
                bList.get(i).stake = 0;
            }
        }
    }
}
