// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./verifier.sol" as verifier;
import "./Utils.sol" as utils;
import "./Structures.sol";

contract HeaderList {
    mapping(uint => Chain) chains;
    event Logger(string message, uint256 someNum1, uint256 someNum2,uint256 someNum3);

    /// @dev Create new blockchain.
    constructor() {
        // init chain 0 with btc genesis
        setupChain(
            0,
            0x000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f,
            1
        );
        // init chain 1 with btc block 729300 (for testing)
        setupChain(
            1,
            0x00000000000000000002a6a5843409a1e07c20f2ad1047d07491e5b86ae09f03,
            729300
        );
        // init chain 2 with bch genesis
        setupChain(
            2,
            0x000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f,
            1
        );
        // init chain 3 with bch block 735600 (for testing)
        setupChain(
            3,
            0x000000000000000002a31d4ad805018f78dc3c1b0e915f11a76fc38019562708,
            735600
        );
    }

    /// @dev Setup blockchain.
    function setupChain(
        uint chainId,
        uint256 genesis,
        uint256 initHeight
    ) private {
        chains[chainId].genesisHash = genesis;
        chains[chainId].mainFork = 0;
        chains[chainId].forkCount = 1;
        chains[chainId].forks[0].forkHeight = 0;
        chains[chainId].forks[0].previousFork = 0;
        chains[chainId].forks[0].previousHeight = 0;
        chains[chainId].forks[0].batches[0].height = initHeight;
        chains[chainId].forks[0].batches[0].cumulativeDifficulty = 1;
        chains[chainId].forks[0].batches[0].lastHeaderHash = chains[chainId]
            .genesisHash;
    }

    /// @dev Find fork contining hash at number or create a new one.
    /// @param chainId id of current blockchain  0,1 - btc 2,3 -bch
    /// @param prevHash Hash that we search for.
    /// @param number Start height.
    /// @return uint256 Fork Id.
    function findFork(
        uint chainId,
        uint256 prevHash,
        uint number
    ) private returns (uint256) {
        Chain storage headerChain = chains[chainId];
        // return 0 fork if does not find anything aditional check is necessary
        // otherwise returns fork number that contains at number last batch with ending hash of prevHash
        for (uint i = 1; i < chains[chainId].forkCount; i++) {
            // if some fork can accept the batch at head
            if (
                headerChain.forks[i].forkHeight == number &&
                headerChain.forks[i].batches[number].lastHeaderHash == prevHash
            ) {
                return i;
            }
            // if new fork needs to be created
            else if (
                headerChain.forks[i].forkHeight >= number &&
                headerChain.forks[i].batches[number].lastHeaderHash == prevHash
            ) {
                headerChain.forks[headerChain.forkCount + 1].previousFork = i;
                headerChain
                    .forks[headerChain.forkCount + 1]
                    .previousHeight = number;
                headerChain.forks[headerChain.forkCount + 1].forkHeight = 1;
                return headerChain.forkCount + 1;
            }
        }
        return 0;
    }

    /// @dev Verifies array of batches and appedns them to storage.
    /// @param chainId id of current blockchain  0,1 - btc 2,3 -bch
    /// @param inputs Array of inputs containing proof and zok argument.
    /// @param startHeight Start height og batch.
    /// @param endHeight End height of the batch.
    function submitBatches(
        uint chainId,
        Input[] memory inputs,
        uint256 startHeight,
        uint256 endHeight
    ) public {
        Chain storage headerChain = chains[chainId];
        verifier.Verifier ver = new verifier.Verifier();
        Output memory firstInput = utils.parseInput(inputs[0].inputs);
        Output memory lastInput = utils.parseInput(inputs[inputs.length-1].inputs);
        Output memory result;
        result.prevHash = firstInput.prevHash;
        result.totalDifficulty = firstInput.totalDifficulty * inputs.length;
        result.lastHash = lastInput.lastHash;
        result.number = endHeight;

        // batch height
        uint256 forkNumber = findFork(chainId, result.prevHash, startHeight-1);

        // batch difficulty
        Fork storage fork = headerChain.forks[forkNumber];
        uint256 currentHash = fork.batches[fork.forkHeight].lastHeaderHash;

        // check that all inputs are vailid and in a chain
        for (uint i=0; i<inputs.length; i++){
            Input memory input = inputs[i];
            verifier.Verifier.Proof memory proof = utils.createProof(input);

            Output memory output = utils.parseInput(input.inputs);
            // must have at least under maximum target refs https://en.bitcoin.it/wiki/Target
            require(output.lastHash < 0x00000000FFFF0000000000000000000000000000000000000000000000000000);
            // verify batch correctness
            require(ver.verifyTx(proof, input.inputs));
            // verify that batches form chain
            require(currentHash == output.prevHash);
            currentHash = output.lastHash;
        }

        // store all input batches as single cumulated batch
        fork.forkHeight = result.number;
        fork.batches[fork.forkHeight].lastHeaderHash = result.lastHash;
        fork.batches[fork.forkHeight].height = result.number;

        // set cumulative diff
        // if the batch is not first, set it to its' diff + previous batch diff
        if(fork.forkHeight > 1) {
            fork.batches[fork.forkHeight].cumulativeDifficulty =
                result.totalDifficulty
                + fork.batches[fork.forkHeight-1].cumulativeDifficulty;
        }
        // else if the batch is first and continues from another branch
        else if ( fork.previousHeight > 1) {
            Fork storage prevFork = headerChain.forks[fork.previousFork];
            fork.batches[fork.forkHeight].cumulativeDifficulty =
                result.totalDifficulty
                + prevFork.batches[fork.previousHeight].cumulativeDifficulty;
        }

        // update main fork if current has more difficulty
        if(headerChain.mainFork != forkNumber) {
            Fork storage mainFork = headerChain.forks[headerChain.mainFork];
            if(fork.batches[fork.forkHeight].cumulativeDifficulty > mainFork.batches[mainFork.forkHeight].cumulativeDifficulty) {
                headerChain.mainFork = forkNumber;
            }
        }
    }

    event ClosestHash(uint256);

    /// @dev Returns closest hash to given height.
    /// @param chainId id of current blockchain 0,1 - btc 2,3 -bch
    /// @param height Requested block height in blockchain.
    /// @return uint256[] - Closest block hash and its height.
    function getClosestHash(
        uint chainId,
        uint height
    ) public returns (uint256[] memory) {
        Chain storage headerChain = chains[chainId];
        return(getClosest(chainId, height, headerChain.mainFork));
    }

    /// @dev Returns closest hash to given height.
    /// @param chainId id of current blockchain 0,1 - btc 2,3 -bch
    /// @param height Requested block height in blockchain.
    /// @param forkNumber Forknumber to search in initially should be 0.
    /// @return uint256[] - Closest block hash and its height.
    function getClosest(
        uint chainId,
        uint height,
        uint forkNumber
    ) private returns (uint256[] memory) {
        Chain storage headerChain = chains[chainId];
        // using undefined array length for geth warpper compatibility
        uint256[] memory ReturnVal = new uint256[](2);
        Fork storage mainFork = headerChain.forks[forkNumber];
        if (height > mainFork.forkHeight) {
            height = mainFork.forkHeight + 1;
        }

        for (uint i = height; i >= 0; i--) {
            // if reached some hash return it
            if (mainFork.batches[i].lastHeaderHash != 0) {
                emit ClosestHash(mainFork.batches[i].lastHeaderHash);
                ReturnVal[0] = mainFork.batches[i].lastHeaderHash;
                ReturnVal[1] = mainFork.batches[i].height;
                return ReturnVal;
            } else if (i == mainFork.previousHeight) {
                // if reached previous fork continue searching in it
                return
                    getClosest(
                        chainId,
                        mainFork.previousHeight,
                        mainFork.previousFork
                    );
            }
        }
        // not found
        emit ClosestHash(0);
        return ReturnVal;
    }
}
