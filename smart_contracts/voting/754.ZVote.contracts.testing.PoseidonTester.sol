// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "../implementation/Poseidon.sol";

contract PoseidonTester is Poseidon {

    constructor(
        uint256 _p, uint256 _t,
        uint256 _nRoundsF,
        uint256 _nRoundsP,
        uint256[] memory _C,
        uint256[] memory _S,
        uint256[][] memory _M,
        uint256[][] memory _P
    ) Poseidon(
        _p, _t, _nRoundsF, _nRoundsP,
        _C, _S, _M, _P
    ) {}

    function poseidonExPub(
        uint256[] memory inputs, uint256 initialState, uint256 nouts
    ) public view returns (uint256[] memory) {
        return poseidonEx(inputs, initialState, nouts);
    }

    function sigmaPub(uint256 input) public view returns (uint256) {
        return sigma(input);
    }

    function arkPub(
        uint256 r, uint256[] memory input
    ) public view returns (uint256[] memory) {
        return ark(r, input);
    }

    function mixMPub(
        uint256[] memory input
    ) public view returns (uint256[] memory) {
        return mixM(input);
    }

    function mixPPub(
        uint256[] memory input
    ) public view returns (uint256[] memory) {
        return mixP(input);
    }

    function mixLastPub(
        uint256 s, uint256[] memory input
    ) public view returns (uint256) {
        return mixLast(s, input);
    }

    function mixSPub(
        uint256 r, uint256[] memory input
    ) public view returns (uint256[] memory) {
        return mixS(r, input);
    }

    function cutprependPub(
        uint256[] memory ar, uint256 x, uint256 c
    ) public pure returns (uint256[] memory) {
        return cutprepend(ar, x, c);
    }

    function getC() public view returns (uint256[] memory) {
        return C;
    }
    function getS() public view returns (uint256[] memory) {
        return S;
    }
    function getM() public view returns (uint256[][] memory) {
        return M;
    }
    function getP() public view returns (uint256[][] memory) {
        return P;
    }
}