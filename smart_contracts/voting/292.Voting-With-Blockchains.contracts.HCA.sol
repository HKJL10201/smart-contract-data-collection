// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;
pragma experimental ABIEncoderV2;

import {VotingBase} from "./VotingBase.sol";

/// @title HCA_Elections
/// @author Kunal Jain, P. Sahithi Reddy, Prince Varshney
/// @notice Implementation for HCA elections
contract HCA_Elections is VotingBase {
    /// @dev sets the number of dummy coins to assign to each voter
    uint8 private numDummyCoins;
    /// @dev flag if the `numDummyCoins` variable has been set
    bool private dummyCoinValueSet = false;

    /// @dev constructor, calls VotingBase constructor
    constructor() VotingBase() {}

    mapping(uint64 => uint64) dummyCoins;
    mapping(uint64 => uint64) dummyCoinStatus;
    mapping(uint64 => bool) voteCoins;
    mapping(uint64 => uint256) voteCoinIndex;
    mapping(uint64 => uint256) voteCoinKey;
    mapping(uint64 => uint64) votesRecved;

    /// @notice set the number of dummy coins for each voter
    /// @param val number of dummy coins
    function setDummyCoinValue(uint8 val) public {
        require(
            electionStage != ElectionStage.REVEALING,
            "Election already underway"
        );
        numDummyCoins = val;
        dummyCoinValueSet = true;
    }

    /// @notice get the number of dummy coins. Raises error if value has not been set
    function getDummyCoinValue() public view returns (uint64) {
        require(dummyCoinValueSet == true, "Value not set yet!");
        return numDummyCoins;
    }

    /// @dev internal function to allot all the coins for each voter
    function allotCoins() private {
        for (uint64 i = 1; i <= numVoters; i++) {
            dummyCoins[i] = numDummyCoins;
            dummyCoinStatus[i] = 0;
            voteCoins[i] = true;
            voteCoinIndex[i] = random(numDummyCoins, 0);
            emit CoinsAllotted(i, dummyCoins[i] + 1);
            voteCoinKey[i] = random(0xffffffffffff, 0);
            bytes32 voteCoinIndexEncrypted = keccak256(
                abi.encodePacked(voteCoinIndex[i] + voteCoinKey[i])
            );
            bytes32 keyEncrypted = keccak256(abi.encodePacked(voteCoinKey[i]));
            emit VoteCoinEncrypted(i, voteCoinIndexEncrypted, keyEncrypted);
        }
    }

    /// @notice endpoint to start the election
    /// @dev calls `allotCoin`
    function startElection() public override startElectionModifier {
        require(
            dummyCoinValueSet == true,
            "Set number of dummy coin for each voter"
        );
        // require(electionStage == ElectionStage.AWAITING_VOTER_LIST); // This is done as part of modifier
        allotCoins();
        for (uint64 i = 1; i <= numCandidates; i++) {
            votesRecved[i] = 0;
        }
        electionStage = ElectionStage.RUNNING;
        emit ElectionStarted();
    }

    /// @notice function to get the index of vote coin for a particular voter
    /// @param voterID ID of the voter
    /// @return uint256 index of vote coin for the voter
    function getVoteCoinIndex(uint64 voterID) public view returns (uint256) {
        require(voterID <= numVoters, "Invalid ID!");
        require(msg.sender == indexToVoter[voterID].addr, "Bad request!");
        require(electionStage == ElectionStage.RUNNING, "No election running!");
        return voteCoinIndex[voterID];
    }

    /// @notice function to get number of coins left for a voter
    /// @param voterID ID of the voter
    /// @return uint64 number of coins left to send
    function coinsLeft(uint64 voterID) public view returns (uint64) {
        if (voteCoins[voterID]) return 1 + dummyCoins[voterID];
        return dummyCoins[voterID];
    }

    /// @notice sends a particular coin from a voter to a candidate
    /// @param voterID ID of the voter
    /// @param candidateID ID of the coin
    /// @param coinIndex index of coin to send
    /// @dev checks whether coin is vote coin or not and updates tally accordingly
    function sendCoin(
        uint64 voterID,
        uint64 candidateID,
        uint8 coinIndex
    ) public {
        require(
            electionStage == ElectionStage.RUNNING,
            "Election not underway!"
        );
        require(voterID <= numVoters, "Invalid voter ID!");
        require(voterID > 0, "Invalid voter ID!");
        require(candidateID <= numCandidates, "Invalid candidate ID!");
        require(candidateID > 0, "Invalid voter ID!");
        require(msg.sender == indexToVoter[voterID].addr, "Bad request!");
        require(coinIndex <= numDummyCoins + 1, "Invalid coin index!");
        if (coinIndex == voteCoinIndex[voterID]) {
            require(
                voteCoins[voterID] == true,
                "Coin already spent! (vote coin)"
            );
            voteCoins[voterID] = false;
            votesRecved[candidateID] += 1;
        } else {
            require(
                (dummyCoinStatus[voterID] & (1 << coinIndex)) == 0,
                "Coin already spent! (dummy coin)"
            );
            dummyCoinStatus[voterID] =
                dummyCoinStatus[voterID] |
                uint64(1 << coinIndex);
            dummyCoins[voterID] -= 1;
        }
        emit CoinSent(voterID, candidateID, coinIndex);
    }

    /// @notice stars reveal phase of election
    function startReveal() public override {
        electionStage = ElectionStage.REVEALING;
    }

    /// @notice ends the election
    /// @dev builds onto the endElectionModifier in `VotingBase` to perform the necessary checks
    function endElection() public override endElectionModifier {
        for (uint64 i = 1; i <= numVoters; i++) {
            emit VoteCoinIndexReveal(i, voteCoinIndex[i], voteCoinKey[i]);
        }
        for (uint64 i = 1; i <= numCandidates; i++) {
            emit DeclareVotes(i, votesRecved[i]);
        }
        electionStage = ElectionStage.NOT_RUNNING;
    }

    /// @notice evaluates and returns the winner of the election
    /// @return uint64 candidate ID of the winner
    function getWinner() public view override returns (uint64) {
        uint64 maxVotes = 0;
        uint64 winnerID = 0;
        for (uint64 i = 1; i <= numCandidates; i++) {
            if (votesRecved[i] > maxVotes) {
                maxVotes = votesRecved[i];
                winnerID = i;
            }
        }
        return winnerID;
    }

    /// @notice clears data for next election
    function clearData() public override clearDataModifier {
        for (uint64 i = 1; i <= numVoters; i++) {
            delete (dummyCoins[i]);
            delete (dummyCoinStatus[i]);
            delete (voteCoins[i]);
            delete (voteCoinIndex[i]);
            delete (voteCoinKey[i]);
        }
        for (uint64 i = 1; i <= numCandidates; i++) {
            delete (votesRecved[i]);
        }
        dummyCoinValueSet = false;
    }

    /// @notice records starting of election
    event ElectionStarted();

    /// @notice records coin allotment
    /// @param voterID ID of the voter
    /// @param numCoins number of coins allotted
    event CoinsAllotted(uint64 voterID, uint64 numCoins);

    /// @notice records the index of vote coin during coin allotment for a user in a sealed way
    /// @param voterID ID of the voter
    /// @param voteCoinIndexEncrypted index of vote coin for the user encrypted with a key
    /// @param keyEncrypted key used to encrypt the index
    event VoteCoinEncrypted(
        uint64 voterID,
        bytes32 voteCoinIndexEncrypted,
        bytes32 keyEncrypted
    );

    /// @notice records a coin being sent
    /// @param voterID ID of the voter
    /// @param candidateID ID of the candidate
    /// @param coinIndex index of the coin being sent
    event CoinSent(uint64 voterID, uint64 candidateID, uint64 coinIndex);

    /// @notice records the reveal of the vote coin for a voter
    /// @param voterID ID of the voter
    /// @param voteCoinIndex index of vote coin
    /// @param voteCoinKey key used to encrypt while announcing
    event VoteCoinIndexReveal(
        uint64 voterID,
        uint256 voteCoinIndex,
        uint256 voteCoinKey
    );
}
