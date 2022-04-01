// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import './verifier.sol' as verifier;

contract HeaderList{
    uint private headerchainTop = 0;

    // batch containing last header hash and total difficulty
    struct Batch {
        uint256 lastHeaderHash;
        uint256 totalDifficulty;
    }
 
    // list of branches navigated by bloc number
    struct Branch {
        uint256 totalDifficulty;
        mapping(uint => Batch) batches;
    }

    // list of all headers defined by their number
    mapping(uint => Branch) private branches;

    //validation output
    struct Output {
        uint256 prevHash;
        uint256 lastHash;
        uint number;
        uint totalDifficulty;
    }

    function parseInput(uint[22] memory input) internal pure returns(Output memory) {
        // last values in first header
        uint256 prevHash = input[11];
        uint256 lastHash = input[0];
        uint256 difficulty = input[1];
        uint256 number = input[2];

        return Output(prevHash, lastHash, number, difficulty);
    }


    function validateProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[22] memory input) public {

        verifier.Verifier ver = new verifier.Verifier();
        verifier.Verifier.Proof memory proof = verifier.Verifier.Proof(
            verifier.Pairing.G1Point(a[0],a[1]),
            verifier.Pairing.G2Point(b[0],b[1]),
            verifier.Pairing.G1Point(c[0],c[1])
        );

        require(ver.verifyTx(proof,input));
        //require(verifierAddress.call(bytes4(sha3("verifyTx(types)")),a,b,c,input));
        // hash has to be at least under maximum target refs https://en.bitcoin.it/wiki/Target         
        Output memory output = parseInput(input);
        if(output.lastHash > 0x00000000FFFF0000000000000000000000000000000000000000000000000000) {
            Branch storage branch = branches[output.number];
            branch.batches[output.lastHash] = Batch(output.lastHash, output.totalDifficulty);
        }
    }
}
