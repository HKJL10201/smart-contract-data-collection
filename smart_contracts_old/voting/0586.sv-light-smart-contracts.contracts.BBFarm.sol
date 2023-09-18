pragma solidity ^0.4.24;

/**
 * BBFarm is a contract to use BBLib to replicate the functionality of
 * SVLightBallotBox within a centralised container (like the Index).
 */

import { BBLibV7 } from "./BBLib.v7.sol";
import { permissioned, payoutAllC } from "./SVCommon.sol";
import "./hasVersion.sol";
import { IxIface } from "./SVIndex.sol";
import "./BPackedUtils.sol";
import "./IxLib.sol";


contract BBFarmEvents {
    event BallotCreatedWithID(uint ballotId);
    event BBFarmInit(bytes4 namespace);
    event Sponsorship(uint ballotId, uint value);
    event Vote(uint indexed ballotId, bytes32 vote, address voter, bytes extra);
    event BallotOnForeignNetwork(bytes32 networkId, uint ballotId);  // added 2018-06-25 for BBFarmForeign support
}


contract BBFarmIface is BBFarmEvents, permissioned, hasVersion, payoutAllC {
    /* global bbfarm getters */

    function getNamespace() external view returns (bytes4);
    function getBBLibVersion() external view returns (uint256);
    function getNBallots() external view returns (uint256);

    /* foreign network integration */

    // requires version >= 3;
    function getVotingNetworkDetails() external view returns (bytes32);

    /* init a ballot */

    // note that the ballotId returned INCLUDES the namespace.
    function initBallot( bytes32 specHash
                       , uint256 packed
                       , IxIface ix
                       , address bbAdmin
                       , bytes24 extraData
                       ) external returns (uint ballotId);
    // requires v3+; also isn't supported on all networks
    function initBallotProxy(uint8 v, bytes32 r, bytes32 s, bytes32[4] params) external returns (uint256 ballotId);

    /* Sponsorship of ballots */

    function sponsor(uint ballotId) external payable;

    /* Voting functions */

    function submitVote(uint ballotId, bytes32 vote, bytes extra) external;
    function submitProxyVote(bytes32[5] proxyReq, bytes extra) external;

    /* Ballot Getters */

    function getDetails(uint ballotId, address voter) external view returns
            ( bool hasVoted
            , uint nVotesCast
            , bytes32 secKey
            , uint16 submissionBits
            , uint64 startTime
            , uint64 endTime
            , bytes32 specHash
            , bool deprecated
            , address ballotOwner
            , bytes16 extraData);

    function getVote(uint ballotId, uint voteId) external view returns (bytes32 voteData, address sender, bytes extra);
    // getVoteAndTime requires v3+
    function getVoteAndTime(uint ballotId, uint voteId) external view returns (bytes32 voteData, address sender, bytes extra, uint castTs);
    function getTotalSponsorship(uint ballotId) external view returns (uint);
    function getSponsorsN(uint ballotId) external view returns (uint);
    function getSponsor(uint ballotId, uint sponsorN) external view returns (address sender, uint amount);
    function getCreationTs(uint ballotId) external view returns (uint);

    /* Admin on ballots */
    function revealSeckey(uint ballotId, bytes32 sk) external;
    function setEndTime(uint ballotId, uint64 newEndTime) external;  // note: testing only
    function setDeprecated(uint ballotId) external;
    function setBallotOwner(uint ballotId, address newOwner) external;
}



contract BBFarm is BBFarmIface {
    using BBLibV7 for BBLibV7.DB;
    using IxLib for IxIface;

    // namespaces should be unique for each bbFarm
    bytes4 constant NAMESPACE = 0x00000001;
    // last 48 bits
    uint256 constant BALLOT_ID_MASK = 0x00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    uint constant VERSION = 3;

    mapping (uint224 => BBLibV7.DB) dbs;
    // note - start at 100 to avoid any test for if 0 is a valid ballotId
    // also gives us some space to play with low numbers if we want.
    uint nBallots = 0;

    /* modifiers */

    modifier req_namespace(uint ballotId) {
        // bytes4() will take the _first_ 4 bytes
        require(bytes4(ballotId >> 224) == NAMESPACE, "bad-namespace");
        _;
    }

    /* Constructor */

    constructor() payoutAllC(msg.sender) public {
        // this bbFarm requires v5 of BBLib (note: v4 deprecated immediately due to insecure submitProxyVote)
        // note: even though we can't test for this in coverage, this has stopped me deploying to kovan with the wrong version tho, so I consider it tested :)
        assert(BBLibV7.getVersion() == 7);
        emit BBFarmInit(NAMESPACE);
    }

    /* base SCs */

    function _getPayTo() internal view returns (address) {
        return owner;
    }

    function getVersion() external pure returns (uint) {
        return VERSION;
    }

    /* global funcs */

    function getNamespace() external view returns (bytes4) {
        return NAMESPACE;
    }

    function getBBLibVersion() external view returns (uint256) {
        return BBLibV7.getVersion();
    }

    function getNBallots() external view returns (uint256) {
        return nBallots;
    }

    function getVotingNetworkDetails() external view returns (bytes32) {
        // 0 in either chainId or networkId spot indicate the local chain
        return bytes32(uint(0) << 192 | uint(0) << 160 | uint160(address(this)));
    }

    /* db lookup helper */

    function getDb(uint ballotId) internal view returns (BBLibV7.DB storage) {
        // cut off anything above 224 bits (where the namespace goes)
        return dbs[uint224(ballotId)];
    }

    /* Init ballot */

    function initBallot( bytes32 specHash
                       , uint256 packed
                       , IxIface ix
                       , address bbAdmin
                       , bytes24 extraData
                ) only_editors() external returns (uint ballotId) {
        // calculate the ballotId based on the last 224 bits of the specHash.
        ballotId = uint224(specHash) ^ (uint256(NAMESPACE) << 224);
        // we need to call the init functions on our libraries
        getDb(ballotId).init(specHash, packed, ix, bbAdmin, bytes16(uint128(extraData)));
        nBallots += 1;

        emit BallotCreatedWithID(ballotId);
    }

    function initBallotProxy(uint8, bytes32, bytes32, bytes32[4]) external returns (uint256) {
        // this isn't supported on the deployed BBFarm
        revert("initBallotProxy not implemented");
    }

    /* Sponsorship */

    function sponsor(uint ballotId) external payable {
        BBLibV7.DB storage db = getDb(ballotId);
        db.logSponsorship(msg.value);
        doSafeSend(db.index.getPayTo(), msg.value);
        emit Sponsorship(ballotId, msg.value);
    }

    /* Voting */

    function submitVote(uint ballotId, bytes32 vote, bytes extra) req_namespace(ballotId) external {
        getDb(ballotId).submitVote(vote, extra);
        emit Vote(ballotId, vote, msg.sender, extra);
    }

    function submitProxyVote(bytes32[5] proxyReq, bytes extra) req_namespace(uint256(proxyReq[3])) external {
        // see https://github.com/secure-vote/tokenvote/blob/master/Docs/DataStructs.md for breakdown of params
        // pr[3] is the ballotId, and pr[4] is the vote
        uint ballotId = uint256(proxyReq[3]);
        address voter = getDb(ballotId).submitProxyVote(proxyReq, extra);
        bytes32 vote = proxyReq[4];
        emit Vote(ballotId, vote, voter, extra);
    }

    /* Getters */

    // note - this is the maxmimum number of vars we can return with one
    // function call (taking 2 args)
    function getDetails(uint ballotId, address voter) external view returns
            ( bool hasVoted
            , uint nVotesCast
            , bytes32 secKey
            , uint16 submissionBits
            , uint64 startTime
            , uint64 endTime
            , bytes32 specHash
            , bool deprecated
            , address ballotOwner
            , bytes16 extraData) {
        BBLibV7.DB storage db = getDb(ballotId);
        uint packed = db.packed;
        return (
            db.getSequenceNumber(voter) > 0,
            db.nVotesCast,
            db.ballotEncryptionSeckey,
            BPackedUtils.packedToSubmissionBits(packed),
            BPackedUtils.packedToStartTime(packed),
            BPackedUtils.packedToEndTime(packed),
            db.specHash,
            db.deprecated,
            db.ballotOwner,
            db.extraData
        );
    }

    function getVote(uint ballotId, uint voteId) external view returns (bytes32 voteData, address sender, bytes extra) {
        (voteData, sender, extra, ) = getDb(ballotId).getVote(voteId);
    }

    function getVoteAndTime(uint ballotId, uint voteId) external view returns (bytes32 voteData, address sender, bytes extra, uint castTs) {
        return getDb(ballotId).getVote(voteId);
    }

    function getSequenceNumber(uint ballotId, address voter) external view returns (uint32 sequence) {
        return getDb(ballotId).getSequenceNumber(voter);
    }

    function getTotalSponsorship(uint ballotId) external view returns (uint) {
        return getDb(ballotId).getTotalSponsorship();
    }

    function getSponsorsN(uint ballotId) external view returns (uint) {
        return getDb(ballotId).sponsors.length;
    }

    function getSponsor(uint ballotId, uint sponsorN) external view returns (address sender, uint amount) {
        return getDb(ballotId).getSponsor(sponsorN);
    }

    function getCreationTs(uint ballotId) external view returns (uint) {
        return getDb(ballotId).creationTs;
    }

    /* ADMIN */

    // Allow the owner to reveal the secret key after ballot conclusion
    function revealSeckey(uint ballotId, bytes32 sk) external {
        BBLibV7.DB storage db = getDb(ballotId);
        db.requireBallotOwner();
        db.requireBallotClosed();
        db.revealSeckey(sk);
    }

    // note: testing only.
    function setEndTime(uint ballotId, uint64 newEndTime) external {
        BBLibV7.DB storage db = getDb(ballotId);
        db.requireBallotOwner();
        db.requireTesting();
        db.setEndTime(newEndTime);
    }

    function setDeprecated(uint ballotId) external {
        BBLibV7.DB storage db = getDb(ballotId);
        db.requireBallotOwner();
        db.deprecated = true;
    }

    function setBallotOwner(uint ballotId, address newOwner) external {
        BBLibV7.DB storage db = getDb(ballotId);
        db.requireBallotOwner();
        db.ballotOwner = newOwner;
    }
}
