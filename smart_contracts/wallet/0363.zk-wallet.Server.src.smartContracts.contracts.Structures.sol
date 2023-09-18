// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

    // single batch of headers containing 
    // can be created by multipole zk batches
    struct Batch {
        uint256 lastHeaderHash;
        uint cumulativeDifficulty;
        uint height;
    }
 
    // list of all forks in the blockchain
    struct Fork {
        uint previousFork;
        uint previousHeight;
        uint forkHeight;
        mapping(uint => Batch) batches;
    }

    // representation of headerchain
    struct Chain {
        uint256 genesisHash;
        uint mainFork;
        mapping(uint => Fork) forks;
        uint forkCount;
    }

    // verifier output
    struct Output {
        uint256 prevHash;
        uint256 lastHash;
        uint number;
        uint totalDifficulty;
    }
    
    // verifier input
    struct Input {
        uint[2] a;
        uint[2][2] b;
        uint[2] c;
        uint256[8] inputs;
    }