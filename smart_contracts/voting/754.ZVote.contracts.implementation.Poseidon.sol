// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract Poseidon {
    uint256 public p;
    uint256 public t;
    uint256 public nRoundsF;
    uint256 public nRoundsP;
    uint256[] public C;
    uint256[] public S;
    uint256[][] public M;
    uint256[][] public P;

    constructor(
        uint256 _p, 
        uint256 _t,
        uint256 _nRoundsF,
        uint256 _nRoundsP,
        uint256[] memory _C,
        uint256[] memory _S,
        uint256[][] memory _M,
        uint256[][] memory _P
    ) {
        p = _p;
        t = _t;
        nRoundsF = _nRoundsF;
        nRoundsP = _nRoundsP;
        C = _C;
        S = _S;
        M = _M;
        P = _P;
    }

    function poseidon(
        uint256[] memory inputs
    ) public view returns (uint256) {
        return poseidonEx(inputs, 0, 1)[0];
    }

    function poseidonEx(
        uint256[] memory inputs, uint256 initialState, uint256 nouts
    ) internal view returns (uint256[] memory) {
        require(inputs.length + 1 == t);

        // set holders
        uint256 sigmaP;
        uint256[] memory sigmaF = new uint256[](t);
        uint256[] memory mix_ = new uint256[](t);
        uint256[] memory mixS_ = new uint256[](t);
        uint256[] memory mixLast_ = new uint256[](nouts);

        // comonly used constants
        uint256 hnRoundsF = nRoundsF / 2;
        uint256 arkshift = (hnRoundsF+1)*t;

        uint256[] memory ark_ = ark(
            0, cutprepend(inputs, initialState, t-1));
        for (uint256 r = 0; r < hnRoundsF-1; r++) {
            for (uint256 j = 0; j < t; j++) {
                if (r == 0)
                    sigmaF[j] = sigma(ark_[j]);
                else 
                    sigmaF[j] = sigma(mix_[j]);
            }
            ark_ = ark((r+1)*t, sigmaF);
            mix_ = mixM(ark_);
        }

        for (uint256 j = 0; j < t; j++) 
            sigmaF[j] = sigma(mix_[j]);
        
        ark_ = ark(hnRoundsF*t, sigmaF);
        mix_ = mixP(ark_);

        for (uint256 r = 0; r < nRoundsP; r++) {
            if (r == 0) 
                sigmaP = sigma(mix_[0]);
            else 
                sigmaP = sigma(mixS_[0]);

            uint256[] memory mixSin = new uint256[](t);
            for (uint256 j = 0; j < t; j++) {
                if (j == 0) 
                    mixSin[j] = addmod(sigmaP, C[arkshift + r], p);
                else {
                    if (r == 0) 
                        mixSin[j] = mix_[j];
                    else 
                        mixSin[j] = mixS_[j];
                }
            }
            mixS_ = mixS(r, mixSin);
        }

        for (uint256 r = 0; r < hnRoundsF-1; r++) {
            for (uint256 j = 0; j < t; j++) {
                if (r == 0)
                    sigmaF[j] = sigma(mixS_[j]);
                else 
                    sigmaF[j] = sigma(mix_[j]);
            }
            ark_ = ark(arkshift + nRoundsP + r*t, sigmaF);
            mix_ = mixM(ark_);
        }

        for (uint256 j = 0; j < t; j++) 
            sigmaF[j] = sigma(mix_[j]);
        
        for (uint256 i = 0; i < nouts; i++) 
            mixLast_[i] = mixLast(i, sigmaF);
        
        return mixLast_;
    }  

    function sigma(uint256 input) internal view returns (uint256) {
        uint256 sqr = mulmod(input, input, p);
        uint256 qut = mulmod(sqr, sqr, p);
        return mulmod(input, qut, p);
    }

    function ark(
        uint256 r, uint256[] memory input
    ) internal view returns (uint256[] memory) {
        uint256[] memory output = new uint256[](t);
        for (uint256 i = 0; i < t; i++) 
            output[i] = addmod(input[i], C[i+r], p);
        return output;
    }

    function mixM(
        uint256[] memory input
    ) internal view returns (uint256[] memory) {
        uint256[] memory output = new uint256[](t);
        for (uint256 i = 0; i < t; i++) {
            uint256 lc = 0;
            for (uint256 j = 0; j < t; j++)
                lc = addmod(lc, mulmod(M[j][i], input[j], p), p);
            output[i] = lc;
        }
        return output;
    }

    function mixP(
        uint256[] memory input
    ) internal view returns (uint256[] memory) {
        uint256[] memory output = new uint256[](t);
        for (uint256 i = 0; i < t; i++) {
            uint256 lc = 0;
            for (uint256 j = 0; j < t; j++)
                lc = addmod(lc, mulmod(P[j][i], input[j], p), p);
            output[i] = lc;
        }
        return output;
    }

    function mixLast(
        uint256 s, uint256[] memory input
    ) internal view returns (uint256) {
        uint256 lc = 0;
        for (uint j = 0; j < t; j++)
            lc = addmod(lc, mulmod(M[j][s], input[j], p), p);
        return lc;
    }

    function mixS(
        uint256 r, uint256[] memory input
    ) internal view returns (uint256[] memory) {
        uint256[] memory output = new uint256[](t);
        uint256 lc = 0;
        uint256 t2m1r = (t * 2 - 1) * r;
        for (uint256 i = 0; i <t; i++)
            lc = addmod(lc, mulmod(S[t2m1r + i], input[i], p), p);
        output[0] = lc;
        for (uint256 i = 1; i < t; i++) 
            output[i] = addmod(
                input[i], 
                mulmod(input[0], S[t2m1r + t + i - 1], p), 
                p
            );
        return output;
    }

    function cutprepend(
        uint256[] memory ar, uint256 x, uint256 c
    ) internal pure returns (uint256[] memory) {
        uint256[] memory output = new uint256[](c+1);
        output[0] = x;
        for (uint256 i = 0; i < c; i++) 
            output[i+1] = ar[i];
        return output;
    }
}