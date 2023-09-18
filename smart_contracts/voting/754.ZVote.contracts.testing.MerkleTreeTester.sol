// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "../implementation/Poseidon.sol";
import "../implementation/MerkleTree.sol";

contract MerkleTreeTester is Poseidon, MerkleTree {

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

    function addElementPub(uint256 x) public {
        addElement(x);
    }

    function hashFunction(
        uint256 a, uint256 b
    ) override internal view returns (uint256) {
        uint256[] memory inputs = new uint256[](2);
        inputs[0] = a;
        inputs[1] = b;
        return poseidon(inputs);
    }

}