pragma solidity ^0.4.24;

/**
 * BBFarm is a contract to use BBLib to replicate the functionality of
 * SVLightBallotBox within a centralised container (like the Index).
 *
 * (c) 2018 SecureVote
 */

import "./BBLib.v7.sol";
import { permissioned, payoutAllC } from "./SVCommon.sol";
import "./hasVersion.sol";
import { IxIface } from "./SVIndex.sol";
import "./BPackedUtils.sol";
import "./IxLib.sol";
import { BBFarmIface } from "./BBFarm.sol";
import "../libs/MemArrApp.sol";
import "../libs/RLPEncode.sol";


library CalcBallotId {
    function calc( bytes4 namespace
                 , bytes32 specHash
                 , uint256 packed
                 , address proposer
                 , bytes24 extraData
            ) internal pure returns (uint256 ballotId) {
        bytes32 midHash = keccak256(abi.encodePacked(specHash, packed, proposer, extraData));
        ballotId = (uint256(namespace) << 224) | uint256(uint224(midHash));
    }
}


/**
 * This contract is on mainnet - should not take votes but should
 * deterministically calculate ballotId
 */
contract RemoteBBFarmProxy is BBFarmIface {
    using BBLibV7 for BBLibV7.DB;

    bytes4 namespace;
    bytes32 foreignNetworkDetails;
    uint constant VERSION = 3;

    // error strings
    string constant noSponsorship = "BBFarm proxy doesn't support sponsorship";
    string constant noVotes = "BBFarm proxy has no knowledge of votes";

    /* storing info about ballots */

    // struct BallotPx {
    //     bytes32 specHash;
    //     uint256 packed;
    //     IxIface index;
    //     address bbOwner;
    //     bytes16 extraData;
    //     uint creationTs;
    //     bool deprecated;
    //     bytes32 secKey;
    // }

    mapping(uint224 => BBLibV7.DB) dbs;
    mapping(uint => uint) ballotNToId;
    uint nBallots = 0;

    /* ballot owner modifier */

    modifier bOwner(uint ballotId) {
        require(getDb(ballotId).ballotOwner == msg.sender, "!owner");
        _;
    }

    /* constructor */

    constructor(bytes4 _namespace, uint32 fNetworkId, uint32 fChainId, address fBBFarm) payoutAllC(msg.sender) public {
        namespace = _namespace;
        // foreignNetworkDetails has the following format:
        //   [uint32 - unallocated]
        //   [uint32 - network id; 0 for curr network]
        //   [uint32 - chain id; 0 for curr chainId]
        //   [uint160 - address of bbFarm on target network]
        // eth mainnet is: [0][1][1][<addr>]
        // eth classic is: [0][1][61][<addr>]
        // ropsten is: [0][3][3][<addr>]  -- TODO confirm
        // kovan is: [0][42][42][<addr>]  -- TODO confirm
        // morden is: [0][2][62][<addr>] -- https://github.com/ethereumproject/go-ethereum/blob/74ab56ba00b27779b2bdbd1c3aef24bdeb941cd8/core/config/morden.json
        // rinkeby is: [0][4][4][<addr>] -- todo confirm
        foreignNetworkDetails = bytes32(uint(fNetworkId) << 192 | uint(fChainId) << 160 | uint(fBBFarm));
    }

    // helper
    function getDb(uint ballotId) internal view returns (BBLibV7.DB storage) {
        // cut off anything above 224 bits (where the namespace goes)
        return dbs[uint224(ballotId)];
    }

    /* global getters */

    function getNamespace() external view returns (bytes4) {
        return namespace;
    }

    function getBBLibVersion() external view returns (uint256) {
        return BBLibV7.getVersion();
    }

    function getNBallots() external view returns (uint256) {
        return nBallots;
    }

    function getVersion() external pure returns (uint256) {
        return VERSION;
    }

    /* foreign integration */

    function getVotingNetworkDetails() external view returns (bytes32) {
        // this is given during construction; format is:
        // [32b unallocated][32b chainId][32b networkId][160b bbFarm addr on foreign network]
        return foreignNetworkDetails;
    }

    /* init of ballots */

    function initBallot( bytes32 specHash
                       , uint256 packed
                       , IxIface ix
                       , address bbOwner
                       , bytes24 extraData
                ) only_editors() external returns (uint ballotId) {
        // calculate the ballotId based on the last 224 bits of the specHash.
        ballotId = ballotId = CalcBallotId.calc(namespace, specHash, packed, bbOwner, extraData);

        // we need to call the init functions on our libraries
        getDb(ballotId).init(specHash, packed, ix, bbOwner, bytes16(uint128(extraData)));

        // we just store a log of the ballot here; no additional logic
        uint bN = nBallots;
        nBallots = bN + 1;
        ballotNToId[bN] = ballotId;

        emit BallotCreatedWithID(ballotId);
        emit BallotOnForeignNetwork(foreignNetworkDetails, ballotId);
    }

    function initBallotProxy(uint8, bytes32, bytes32, bytes32[4]) external returns (uint256) {
        // we don't support initBallotProxy on mainnet
        revert("no ballot-proxy support");
    }

    /* Sponsorship */

    function sponsor(uint) external payable {
        // no sponsorship support for remote ballots
        revert(noSponsorship);
    }

    /* Voting */

    function submitVote(uint, bytes32, bytes) /*req_namespace(ballotId)*/ external {
        revert(noVotes);  // no voting support for px
    }

    function submitProxyVote(bytes32[5], bytes) /*req_namespace(uint256(proxyReq[3]))*/ external {
        revert(noVotes);  // no voting support for px
    }

    /* Getters */

    function getDetails(uint ballotId, address) external view returns
            ( bool hasVoted             // 0
            , uint nVotesCast           // 1
            , bytes32 secKey            // 2
            , uint16 submissionBits     // 3
            , uint64 startTime          // 4
            , uint64 endTime            // 5
            , bytes32 specHash          // 6
            , bool deprecated           // 7
            , address ballotOwner       // 8
            , bytes16 extraData) {      // 9
        BBLibV7.DB storage b = getDb(ballotId);
        uint packed = b.packed;
        return (
            false,
            // this is a very big number (>2^255) that is obviously non arbitrary
            // - idea is to deliberately cause a failure case if using bbFarmPx incorrectly.
            113370313370313370313370313370313370313370313370313370313370313370313370313370,
            b.ballotEncryptionSeckey,
            BPackedUtils.packedToSubmissionBits(packed),
            BPackedUtils.packedToStartTime(packed),
            BPackedUtils.packedToEndTime(packed),
            b.specHash,
            b.deprecated,
            b.ballotOwner,
            b.extraData
        );
    }

    function getVote(uint, uint) external view returns (bytes32, address, bytes) {
        revert(noVotes);
    }

    function getVoteAndTime(uint, uint) external view returns (bytes32, address, bytes, uint) {
        revert(noVotes);
    }

    function getSequenceNumber(uint, address) external pure returns (uint32) {
        revert(noVotes);
    }

    function getTotalSponsorship(uint) external view returns (uint) {
        revert(noSponsorship);
    }

    function getSponsorsN(uint) external view returns (uint) {
        revert(noSponsorship);
    }

    function getSponsor(uint, uint) external view returns (address, uint) {
        revert(noSponsorship);
    }

    function getCreationTs(uint ballotId) external view returns (uint) {
        return getDb(ballotId).creationTs;
    }

    /* ADMIN */

    // Allow the owner to reveal the secret key after ballot conclusion
    function revealSeckey(uint ballotId, bytes32 secKey) external bOwner(ballotId) {
        BBLibV7.DB storage b = getDb(ballotId);
        require(BPackedUtils.packedToEndTime(b.packed) < now, "!ended");
        b.ballotEncryptionSeckey = secKey;
    }

    // note: testing only.
    function setEndTime(uint ballotId, uint64 newEndTime) external bOwner(ballotId) {
        BBLibV7.DB storage b = getDb(ballotId);
        require(BBLibV7.isTesting(BPackedUtils.packedToSubmissionBits(b.packed)), "!testing");
        b.packed = BPackedUtils.setEndTime(b.packed, newEndTime);
    }

    function setDeprecated(uint ballotId) external bOwner(ballotId) {
        BBLibV7.DB storage b = getDb(ballotId);
        b.deprecated = true;
    }

    function setBallotOwner(uint ballotId, address newOwner) external bOwner(ballotId) {
        BBLibV7.DB storage b = getDb(ballotId);
        b.ballotOwner = newOwner;
    }
}


/**
 * This BBFarm lives on classic (or wherever) and does take votes
 * (often / always by proxy) and calculates the same ballotId as
 * above. Does _not_ require init'ing the ballot first
 */
contract RemoteBBFarm is BBFarmIface {
    // libs
    using BBLibV7 for BBLibV7.DB;
    using MemArrApp for bytes32[];
    using MemArrApp for bytes[];
    using MemArrApp for address[];
    using MemArrApp for uint[];

    // error messages
    string constant noInitBallot = "Initing ballots not supported on remote";
    string constant noSponsorship = "BBFarm remote doesn't support sponsorship";

    // namespaces should be unique for each bbFarm
    bytes4 namespace;

    uint constant VERSION = 3;

    mapping (uint224 => BBLibV7.DB) dbs;
    uint nBallots = 0;

    /* modifiers */

    modifier req_namespace(uint ballotId) {
        // bytes4() will take the _first_ 4 bytes
        require(bytes4(ballotId >> 224) == namespace, "bad-namespace");
        _;
    }

    /* Constructor */

    constructor(bytes4 _namespace) payoutAllC(msg.sender) public {
        assert(BBLibV7.getVersion() == 7);
        namespace = _namespace;
        emit BBFarmInit(_namespace);
    }

    /* base SCs */

    // don't need this because no payable methods
    // function _getPayTo() internal view returns (address) {
    //     return owner;
    // }

    function getVersion() external pure returns (uint) {
        return VERSION;
    }

    /* global funcs */

    function getNamespace() external view returns (bytes4) {
        return namespace;
    }

    function getBBLibVersion() external view returns (uint256) {
        return BBLibV7.getVersion();
    }

    function getNBallots() external view returns (uint256) {
        return nBallots;
    }

    function getVotingNetworkDetails() external view returns (bytes32) {
        return bytes32(uint(this));
    }

    /* db lookup helper */

    function getDb(uint ballotId) internal view returns (BBLibV7.DB storage) {
        // cut off anything above 224 bits (where the namespace goes)
        return dbs[uint224(ballotId)];
    }

    /* Init ballot */

    function initBallot( bytes32
                       , uint256
                       , IxIface
                       , address
                       , bytes24
                ) /*only_editors()*/ external returns (uint) {
        // we cannot call initBallot on a BBFarmRemote (since it should only be called by editors, and they don't exist here)
        revert(noInitBallot);
    }

    /*uint8 v, bytes32 r, bytes32 s, bytes32[4] params*/
    function initBallotProxy(uint8, bytes32, bytes32, bytes32[4]) external returns (uint256 /*ballotId*/) {
        // do not allow proxy ballots either atm -- planned for future versions
        revert(noInitBallot);
        // // params is a bytes32[4] of [specHash, packed, proposer, extraData]
        // bytes32 specHash = params[0];
        // uint256 packed = uint256(params[1]);
        // address proposer = address(params[2]);
        // bytes24 extraData = bytes24(params[3]);

        // bytes memory signed = abi.encodePacked(specHash, packed, proposer, extraData);
        // bytes32 msgHash = keccak256(signed);

        // address proposerRecovered = ecrecover(msgHash, v, r, s);
        // require(proposerRecovered == proposer, "bad-proposer");

        // ballotId = CalcBallotId.calc(namespace, specHash, packed, proposer, extraData);
        // getDb(ballotId).init(specHash, packed, IxIface(0), proposer, bytes16(uint128(extraData)));
        // nBallots += 1;

        // emit BallotCreatedWithID(ballotId);
    }

    /* Sponsorship */

    function sponsor(uint) external payable {
        // no sponsorship on foreign networks
        revert(noSponsorship);
    }

    /* Voting */

    function submitVote(uint ballotId, bytes32 vote, bytes extra) req_namespace(ballotId) external {
        getDb(ballotId).submitVoteAlways(vote, extra);
        emit Vote(ballotId, vote, msg.sender, extra);
    }

    function submitProxyVote(bytes32[5] proxyReq, bytes extra) req_namespace(uint256(proxyReq[3])) external {
        // see https://github.com/secure-vote/tokenvote/blob/master/Docs/DataStructs.md for breakdown of params
        // pr[3] is the ballotId, and pr[4] is the vote
        uint ballotId = uint256(proxyReq[3]);
        address voter = getDb(ballotId).submitProxyVoteAlways(proxyReq, extra);
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

    function getVote(uint, uint) external view returns (bytes32, address, bytes) {
        // don't let users use getVote since it's unsafe without taking the casting time into account
        revert("getVote unsafe due to no casting time returned");
    }

    function getVoteAndTime(uint ballotId, uint voteId) external view returns (bytes32 voteData, address sender, bytes extra, uint castTs) {
        return getDb(ballotId).getVote(voteId);
    }

    function _getVotes(uint ballotId, uint startTs, uint endTs, address _voter) internal view returns (
        bytes32[] memory voteDatas,
        address[] memory voters,
        bytes memory extrasRLP,
        uint[] memory castTss
    ) {
        address voter;
        uint castTs;
        bytes[] memory extrasEncoded;
        BBLibV7.DB storage db = getDb(ballotId);
        uint nVotes = db.nVotesCast;
        for (uint i = 0; i < nVotes; i++) {
            // add vote to return list if times are okay and _either_ we didn't get
            // a voter's address passed in, or the vote matches the supplied voter
            (, voter,, castTs) = db.getVote(i);
            if (startTs <= castTs && castTs <= endTs && (_voter == address(0) || voter == _voter)) {
                voteDatas = voteDatas.appendBytes32(db.votes[i].voteData);
                extrasEncoded = extrasEncoded.appendBytes(RLPEncode.encodeBytes(db.votes[i].extra));
                voters = voters.appendAddress(voter);
                castTss = castTss.appendUint256(castTs);
            }
        }
        extrasRLP = RLPEncode.encodeList(extrasEncoded);
    }

    function getVotesBetween(uint ballotId, uint startTs, uint endTs) external view returns (
        bytes32[] memory voteDatas,
        address[] memory voters,
        bytes memory extrasRLP,
        uint[] memory castTss
    ) {
        return _getVotes(ballotId, startTs, endTs, address(0));
    }

    function getVotesBetweenFor(uint ballotId, uint startTs, uint endTs, address voter) external view returns (
        bytes32[] memory voteDatas,
        bytes memory extrasRLP,
        uint[] memory castTss
    ) {
        (voteDatas, , extrasRLP, castTss) = _getVotes(ballotId, startTs, endTs, voter);
    }

    function getSequenceNumber(uint ballotId, address voter) external view returns (uint32 sequence) {
        return getDb(ballotId).getSequenceNumber(voter);
    }

    function getTotalSponsorship(uint ballotId) external view returns (uint) {
        revert(noSponsorship);
    }

    function getSponsorsN(uint ballotId) external view returns (uint) {
        revert(noSponsorship);
    }

    function getSponsor(uint ballotId, uint sponsorN) external view returns (address sender, uint amount) {
        revert(noSponsorship);
    }

    function getCreationTs(uint ballotId) external view returns (uint) {
        revert("creationTs unk on remote");
    }

    /* ADMIN */

    string constant noOwner = "remote BBFarm doesn't know about ballot owners";

    // Allow the owner to reveal the secret key after ballot conclusion
    function revealSeckey(uint, bytes32) external {
        revert(noOwner);
    }

    // note: testing only.
    function setEndTime(uint, uint64) external {
        revert(noOwner);
    }

    function setDeprecated(uint) external {
        revert(noOwner);
    }

    function setBallotOwner(uint, address) external {
        revert(noOwner);
    }
}
