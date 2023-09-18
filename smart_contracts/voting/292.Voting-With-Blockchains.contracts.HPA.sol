// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;
pragma experimental ABIEncoderV2;

import {VotingBase} from "./VotingBase.sol";

contract HPA_Elections is VotingBase {
    /// @dev number of account for each user
    uint256 private numAccounts;
    /// @dev flag whether `numAccounts` has been set or not
    bool private numAccountsValueSet = false;

    /// @dev constructor for the class, calls `VotingBase` constructor
    constructor() VotingBase() {}

    mapping(uint256 => uint64) accountNumberToCandidate;
    mapping(uint64 => uint64) votesRecved;
    mapping(uint64 => uint256[]) accountsForCandidate;
    mapping(uint64 => uint256[]) accountsToVoters;

    /// @notice set the number of accounts for each candidate
    /// @param X number of accounts
    function setNumberOfAccounts(uint256 X) public {
        require(
            electionStage != ElectionStage.REVEALING,
            "Election already underway"
        );
        numAccounts = X;
        numAccountsValueSet = true;
    }

    /// @notice gets number of accounts for each user. Returns error if not set
    function getNumberOfAccounts() public view returns (uint256) {
        require(numAccountsValueSet == true, "Value not set");
        return numAccounts;
    }

    /// @dev internal function to allot the accounts
    function allotAccounts() private {
        for (uint256 i = 0; i < numAccounts * numCandidates; i++) {
            accountNumberToCandidate[i] = convert256to64(
                random(numCandidates + 1, 1)
            );
            accountsForCandidate[accountNumberToCandidate[i]].push(i);
        }
        for (uint64 i = 1; i <= numVoters; i++) {
            for (uint64 j = 1; j <= numCandidates; j++) {
                require(accountsForCandidate[j].length > 0, uint2str(j));
                uint256 idx = random(
                    convert256to64(accountsForCandidate[j].length - 1),
                    0
                );
                accountsToVoters[i].push(accountsForCandidate[j][idx]);
            }
        }
        for (uint64 i = 1; i <= numCandidates; i++) {
            votesRecved[i] = 0;
        }
    }

    /// @notice starts the election
    /// @dev calls the `allotAccounts` function
    function startElection() public override startElectionModifier {
        require(
            numAccountsValueSet == true,
            "Set number of accounts for each candidate"
        );
        allotAccounts();
        electionStage = ElectionStage.RUNNING;
        emit AccountsAllotted();
    }

    /// @notice function to get the account ID of a particular candidate for a particular voter
    /// @param voterID ID of the voter
    /// @param candidateID ID of the candidate
    /// @return uint256 the account ID of the candidate for that voter
    function getCandidateAccount(uint64 voterID, uint64 candidateID)
        public
        view
        returns (uint256)
    {
        require(voterID <= numVoters, "Invalid voter ID");
        require(candidateID <= numVoters, "Invalid candidate ID");
        require(voterID > 0, "Invalid voter ID");
        require(candidateID > 0, "Invalid candidate ID");
        require(
            electionStage == ElectionStage.RUNNING,
            "Election not underway"
        );
        require(msg.sender == indexToVoter[voterID].addr, "Bad request");
        return accountsToVoters[voterID][candidateID - 1];
    }

    /// @notice send vote from voter
    /// @param voterID ID of the voter
    /// @param candidateAccount account ID to send vote to
    function sendVote(uint64 voterID, uint256 candidateAccount) public {
        require(voterID <= numVoters, "Invalid voter ID");
        require(voterID > 0, "Invalid voter ID");
        require(msg.sender == indexToVoter[voterID].addr, "Bad request");
        require(
            accountsToVoters[voterID][
                accountNumberToCandidate[candidateAccount] - 1
            ] == candidateAccount,
            "Account not allotted to you"
        );
        votesRecved[accountNumberToCandidate[candidateAccount]] += 1;
        emit VoteSend(voterID, candidateAccount);
    }

    /// @notice starts reveal phase
    function startReveal() public override {
        electionStage = ElectionStage.REVEALING;
    }

    /// @notice ends the election
    function endElection() public override endElectionModifier {
        for (uint64 i = 0; i < numCandidates * numAccounts; i++) {
            emit RevealAccountToCandidate(i, accountNumberToCandidate[i]);
        }
        for (uint64 i = 1; i <= numCandidates; i++) {
            emit DeclareVotes(i, votesRecved[i]);
        }
        electionStage = ElectionStage.NOT_RUNNING;
    }

    /// @notice function to get the winner of the election
    /// @return uint64 ID of the candidate
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
        for (uint64 i = 1; i <= numCandidates; i++) {
            delete (accountsForCandidate[i]);
            delete (votesRecved[i]);
        }
        for (uint64 i = 1; i <= numVoters; i++) {
            delete (accountsToVoters[i]);
        }
        for (uint256 i = 0; i < numCandidates * numAccounts; i++) {
            delete (accountNumberToCandidate[i]);
        }
        numAccountsValueSet = false;
    }

    /// @notice records allotment of accounts
    event AccountsAllotted();

    /// @notice records vote being sent
    /// @param voterID ID of the voter
    /// @param accountNumber account number to send the vote to
    event VoteSend(uint64 voterID, uint256 accountNumber);

    /// @notice records which account is allotted to which candidate
    /// @param accoutnNumber account number
    /// @param candidateID ID of the candidate
    event RevealAccountToCandidate(uint256 accoutnNumber, uint64 candidateID);
}
