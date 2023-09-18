//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./VotingPlatformLib.sol";

contract Vote {
    bool public multipleChoice;
    uint public dateOfCreating;
    uint public dateOfStart;
    uint public dateOfEnd;
    uint public dateOfEndAddPrivateKeys;
    VotingPlatformLib.Candidate[] public candidates;
    uint public votersCount;
    uint public modulus;
    uint public exponent;
    uint[] public verifiedSignature;
    Ballot[] public ballots;

    struct Ballot {
        address owner;
        bytes encryptedValue;
        bytes privateKey;
        uint dateOfVote;
    }

    event BallotAdded(uint index, address sender, uint signature);

    modifier votingCreateDateTimeCheck(uint _dateOfStart, uint _dateOfEnd, uint _dateOfEndAddPrivateKeys) {
        require(_dateOfStart < _dateOfEnd, 'End date of voting must be later than start date');
        require(_dateOfEnd <= _dateOfEndAddPrivateKeys, 'The time to add decryption keys must be greater than or equal to the end time of voting');
        _;
    }

    constructor(
        bool _multipleChoice,
        uint _dateOfStart,
        uint _dateOfEnd,
        uint _dateOfEndAddPrivateKeys,
        VotingPlatformLib.Candidate[] memory _candidates,
        uint _votersCount,
        uint _modulus,
        uint _exponent
    ) votingCreateDateTimeCheck(_dateOfStart, _dateOfEnd, _dateOfEndAddPrivateKeys) {
        multipleChoice = _multipleChoice;
        dateOfCreating = block.timestamp;
        dateOfStart = _dateOfStart;
        dateOfEnd = _dateOfEnd;
        dateOfEndAddPrivateKeys = _dateOfEndAddPrivateKeys;
        votersCount = _votersCount;
        modulus = _modulus;
        exponent = _exponent;
        for (uint32 i = 0; i < _candidates.length; i += 1) {
            candidates.push(_candidates[i]);
        }
    }

    modifier ballotDateTimeCheck() {
        require(block.timestamp >= dateOfStart, 'Voting has not started');
        require(block.timestamp < dateOfEnd, 'Voting is over');
        _;
    }

    modifier signNotUsed(uint signature) {
        bool isFind = false;
        for (uint i = 0; i < verifiedSignature.length; i += 1) {
            if (signature == verifiedSignature[i]) {
                isFind = true;
            }
        }
        require(!isFind, 'Signature has already been used to vote');
        _;
    }

    modifier ballotOwnerCheck(uint index) {
        require(ballots[index].owner == msg.sender, 'You are not the ballot owner');
        _;
    }

    modifier ballotPrivateKeyNotSet(uint index) {
        require(keccak256(abi.encodePacked(ballots[index].privateKey)) == keccak256(abi.encodePacked('0x0')), 'Private key already set');
        _;
    }

    modifier ballotPrivateKeyPushTimeNotEnd() {
        require(block.timestamp <= dateOfEndAddPrivateKeys, 'Time to add decryption keys ends');
        _;
    }

    modifier signVerify(uint _originalMessage, uint _signature) {
        bytes32 compareOne = keccak256(abi.encodePacked(_originalMessage));
        bytes32 compareTwo = keccak256(abi.encodePacked(expMod(_signature, modulus, exponent)));

        require(compareOne == compareTwo, 'Signature not verified');
        _;
    }

    modifier numberOfVotesCheck() {
        require(ballots.length + 1 <= votersCount, 'Ballots exceeded');
        _;
    }

    function expMod(
        uint _signature,
        uint _modulus,
        uint _exponent
    ) internal view returns (uint _o) {
        assembly {
        // define pointer
            let p := mload(0x40)
        // store data assembly-favouring ways
            mstore(p, 0x20) // Length of Base
            mstore(add(p, 0x20), 0x20) // Length of Exponent
            mstore(add(p, 0x40), 0x20) // Length of Modulus
            mstore(add(p, 0x60), _signature) // Base
            mstore(add(p, 0x80), _exponent) // Exponent
            mstore(add(p, 0xa0), _modulus) // Modulus
            if iszero(staticcall(sub(gas(), 2000), 0x05, p, 0xc0, p, 0x20)) {
                revert(0, 0)
            }
        // data
            _o := mload(p)
        }
    }

    function getCandidateCount() external view returns (uint) {
        return candidates.length;
    }

    function getBallotCount() external view returns (uint) {
        return ballots.length;
    }

    function getVerifiedSignatureCount() external view returns (uint) {
        return verifiedSignature.length;
    }

    function pushBallot(
        bytes memory _encryptedValue,
        uint _originalMessageHash,
        uint _signature
    ) public signVerify(_originalMessageHash, _signature) signNotUsed(_signature) numberOfVotesCheck ballotDateTimeCheck {
        ballots.push(Ballot({
            owner : msg.sender,
            encryptedValue : _encryptedValue,
            privateKey : '0x0',
            dateOfVote : block.timestamp
        }));
        verifiedSignature.push(_signature);
        emit BallotAdded(ballots.length - 1, msg.sender, _signature);
    }

    function pushBallotPrivateKey(
        uint index,
        bytes memory _privateKey
    ) public ballotOwnerCheck(index) ballotPrivateKeyNotSet(index) ballotPrivateKeyPushTimeNotEnd returns (Ballot memory) {
        ballots[index].privateKey = _privateKey;
        return ballots[index];
    }
}
