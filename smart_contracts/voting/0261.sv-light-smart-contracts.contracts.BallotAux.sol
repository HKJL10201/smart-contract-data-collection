pragma solidity 0.4.24;

/**
 * DEPRECATED NOW
 * Auxillary functions for ballots.
 * This hosts code that usually returns a memory array, but isn't stuff that
 * we want to bloat every ballot box with. e.g. `getBallotsEthFrom`
 *
 * The code is still here bc we use it for testing
 */


import "./BBLib.v7.sol";
import "./BPackedUtils.sol";
import { BBFarmIface } from "./BBFarm.sol";


interface BBAuxIface {
    function isTesting(BallotBoxIface bb) external view returns (bool);
    function isOfficial(BallotBoxIface bb) external view returns (bool);
    function isBinding(BallotBoxIface bb) external view returns (bool);
    function qualifiesAsCommunityBallot(BallotBoxIface bb) external view returns (bool);


    function isDeprecated(BallotBoxIface bb) external view returns (bool);
    function getEncSeckey(BallotBoxIface bb) external view returns (bytes32);
    function getSpecHash(BallotBoxIface bb) external view returns (bytes32);
    function getSubmissionBits(BallotBoxIface bb) external view returns (uint16);
    function getStartTime(BallotBoxIface bb) external view returns (uint64);
    function getEndTime(BallotBoxIface bb) external view returns (uint64);
    function getNVotesCast(BallotBoxIface bb) external view returns (uint256 nVotesCast);

    function hasVoted(BallotBoxIface bb, address voter) external view returns (bool hv);
}


interface BallotBoxIface {
    function getVersion() external pure returns (uint256);

    function getVote(uint256) external view returns (bytes32 voteData, address sender, bytes32 encPK);

    function getDetails(address voter) external view returns (
        bool hasVoted,
        uint nVotesCast,
        bytes32 secKey,
        uint16 submissionBits,
        uint64 startTime,
        uint64 endTime,
        bytes32 specHash,
        bool deprecated,
        address ballotOwner);

    function getTotalSponsorship() external view returns (uint);

    function submitVote(bytes32 voteData, bytes32 encPK) external;

    function revealSeckey(bytes32 sk) external;
    function setEndTime(uint64 newEndTime) external;
    function setDeprecated() external;

    function setOwner(address) external;
    function getOwner() external view returns (address);

    event CreatedBallot(bytes32 specHash, uint64 startTs, uint64 endTs, uint16 submissionBits);
    event SuccessfulVote(address indexed voter, uint voteId);
    event SeckeyRevealed(bytes32 secretKey);
}


contract BallotAux is BBAuxIface {
    address constant zeroAddr = address(0);

    function isTesting(BallotBoxIface bb) external view returns (bool) {
        return BBLibV7.isTesting(getSubmissionBits(bb));
    }

    function isOfficial(BallotBoxIface bb) external view returns (bool) {
        return BBLibV7.isOfficial(getSubmissionBits(bb));
    }

    function isBinding(BallotBoxIface bb) external view returns (bool) {
        return BBLibV7.isBinding(getSubmissionBits(bb));
    }

    function qualifiesAsCommunityBallot(BallotBoxIface bb) external view returns (bool) {
        return BBLibV7.qualifiesAsCommunityBallot(getSubmissionBits(bb));
    }

    function isDeprecated(BallotBoxIface bb) external view returns (bool deprecated) {
        (,,,,,,, deprecated,) = bb.getDetails(zeroAddr);
    }

    function getEncSeckey(BallotBoxIface bb) external view returns (bytes32 secKey) {
        (,, secKey,,,,,,) = bb.getDetails(zeroAddr);
    }

    function getSpecHash(BallotBoxIface bb) external view returns (bytes32 specHash) {
        (,,,,,, specHash,,) = bb.getDetails(zeroAddr);
    }

    function getSubmissionBits(BallotBoxIface bb) public view returns (uint16 submissionBits) {
        (,,, submissionBits,,,,,) = bb.getDetails(zeroAddr);
    }

    function getStartTime(BallotBoxIface bb) external view returns (uint64 startTime) {
        (,,,, startTime,,,,) = bb.getDetails(zeroAddr);
    }

    function getEndTime(BallotBoxIface bb) external view returns (uint64 endTime) {
        (,,,,, endTime,,,) = bb.getDetails(zeroAddr);
    }

    function getNVotesCast(BallotBoxIface bb) public view returns (uint256 nVotesCast) {
        (, nVotesCast,,,,,,,) = bb.getDetails(zeroAddr);
    }

    function hasVoted(BallotBoxIface bb, address voter) external view returns (bool hv) {
        ( hv,,,,,,,,) = bb.getDetails(voter);
    }
}


contract BBFarmProxy {
    uint ballotId;
    BBFarmIface farm;

    constructor(BBFarmIface _farm, uint _ballotId) public {
        farm = _farm;
        ballotId = _ballotId;
    }

    function getDetails(address voter) external view returns
            ( bool hasVoted
            , uint nVotesCast
            , bytes32 secKey
            , uint16 submissionBits
            , uint64 startTime
            , uint64 endTime
            , bytes32 specHash
            , bool deprecated
            , address ballotOwner
            , bytes24 extraData) {
        return farm.getDetails(ballotId, voter);
    }
}
