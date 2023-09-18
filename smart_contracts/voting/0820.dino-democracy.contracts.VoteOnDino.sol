// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract VoteOnDino {
    struct DinoName {
        bytes32 name;
        address submitter;
        uint256 votes;
    }

    DinoName[] public dinoNames;
    mapping(bytes32 => bool) knownDinoNames;
    uint256 public dinoNamesCount = 0;

    uint256 public voteEndTime;
    bool public ended = false;
    DinoName winner;

    event DinoVoteEnded(bytes32 name, address submitter, uint256 votes);
    event DinoVotedOn(bytes32 name, uint256 votes);

    /// This dino name has already been proposed.
    error DinoNameAlreadyProposed();
    /// The dino vote has not ended yet.
    error DinoVoteNotEnded();
    /// The dino vote has already ended.
    error DinoVoteAlreadyEnded();
    /// There were no dino names proposed.
    error NoDinoNamesProposed();
    /// This dino name does not exists.
    error DinoNameDoesNotExist();

    constructor(uint256 _votingTime) {
        voteEndTime = block.timestamp + _votingTime;
    }

    function addDinoName(bytes32 dinoName) public {
        require(!ended);
        if (isDinoName(dinoName)) revert DinoNameAlreadyProposed();
        knownDinoNames[dinoName] = true;
        dinoNames.push(
            DinoName({name: dinoName, votes: 0, submitter: msg.sender})
        );
        dinoNamesCount++;
    }

    function getDinoNamesCount() public view returns (uint256 length) {
        return (dinoNames.length);
    }

    function isDinoName(bytes32 dinoName) public view returns (bool) {
        return knownDinoNames[dinoName];
    }

    function voteEnd() public {
        if (block.timestamp < voteEndTime) revert DinoVoteNotEnded();
        if (ended) revert DinoVoteAlreadyEnded();

        ended = true;
        winningProposal();

        for (uint256 i = 0; i < dinoNames.length; i++) {
            // delete doesn't actually remove from array.length calls
            // just nulls values out (need better delete function)
            delete knownDinoNames[dinoNames[i].name];
            delete dinoNames[i];
        }
        dinoNamesCount = 0;

        emit DinoVoteEnded(winner.name, winner.submitter, winner.votes);
    }

    function winningProposal() public {
        require(ended);
        if (dinoNames.length == 0) revert NoDinoNamesProposed();

        DinoName memory _winner = dinoNames[0];
        for (uint256 i = 0; i < dinoNames.length; i++) {
            if (dinoNames[i].votes >= _winner.votes) _winner = dinoNames[i];
        }
        winner = _winner;
    }

    function winningName() public view returns (bytes32 name) {
        require(ended);
        name = winner.name;
    }

    function voteDinoName(bytes32 dinoName) public {
        // Known bug: address can vote on name more than once
        require(!ended);
        if (!isDinoName(dinoName)) revert DinoNameDoesNotExist();
        if (ended) revert DinoVoteAlreadyEnded();

        uint256 i;
        for (i = 0; i < dinoNames.length; i++) {
            if (dinoNames[i].name == dinoName) {
                dinoNames[i].votes++;
                break;
            }
        }

        emit DinoVotedOn(dinoNames[i].name, dinoNames[i].votes);
    }
}
