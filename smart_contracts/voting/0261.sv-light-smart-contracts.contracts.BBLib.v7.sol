pragma solidity 0.4.24;


/**
 * This is a library to manage all ballot box functions. The idea is that
 * ballot box contracts should the the _minimum_ code required to be deployed
 * which means most (ideally all) functions should be moved here.
 */


import "./SVCommon.sol";
import "./SVIndex.sol";
import "./SVBallotConsts.sol";
import "./BPackedUtils.sol";
import "../libs/BytesLib.sol";


library BBLibV7 {
    using BytesLib for bytes;

    // ballot meta
    uint256 constant BB_VERSION = 7;
    /* 4 deprecated due to insecure vote by proxy
       5 deprecated to
        - add `returns (address)` to submitProxyVote
       7 - adds submitVoteAlways (does not check open/close time)
           useful for remote bbfarms
    */

    // voting settings
    uint16 constant USE_ETH = 1;          // 2^0
    uint16 constant USE_SIGNED = 2;       // 2^1
    uint16 constant USE_NO_ENC = 4;       // 2^2
    uint16 constant USE_ENC = 8;          // 2^3

    // ballot settings
    uint16 constant IS_BINDING = 8192;    // 2^13
    uint16 constant IS_OFFICIAL = 16384;  // 2^14
    uint16 constant USE_TESTING = 32768;  // 2^15

    // other consts
    uint32 constant MAX_UINT32 = 0xFFFFFFFF;

    //// ** Storage Variables

    // struct for ballot
    struct Vote {
        bytes32 voteData;
        bytes32 castTsAndSender;
        bytes extra;
    }

    struct Sponsor {
        address sender;
        uint amount;
    }

    //// ** Events
    event CreatedBallot(bytes32 _specHash, uint64 startTs, uint64 endTs, uint16 submissionBits);
    event SuccessfulVote(address indexed voter, uint voteId);
    event SeckeyRevealed(bytes32 secretKey);
    event TestingEnabled();
    event DeprecatedContract();


    // The big database struct


    struct DB {
        // Maps to store ballots, along with corresponding log of voters.
        // Should only be modified through internal functions
        mapping (uint256 => Vote) votes;
        uint256 nVotesCast;

        // we need replay protection for proxy ballots - this will let us check against a sequence number
        // note: votes directly from a user ALWAYS take priority b/c they do not have sequence numbers
        // (sequencing is done by Ethereum itself via the tx nonce).
        mapping (address => uint32) sequenceNumber;

        // NOTE - We don't actually want to include the encryption PublicKey because _it's included in the ballotSpec_.
        // It's better to ensure ppl actually have the ballot spec by not including it in the contract.
        // Plus we're already storing the hash of the ballotSpec anyway...

        // Private key to be set after ballot conclusion - curve25519
        bytes32 ballotEncryptionSeckey;

        // packed contains:
        // 1. Timestamps for start and end of ballot (UTC)
        // 2. bits used to decide which options are enabled or disabled for submission of ballots
        uint256 packed;

        // specHash by which to validate the ballots integrity
        bytes32 specHash;
        // extradata if we need it - allows us to upgrade spechash format, etc
        bytes16 extraData;

        // allow tracking of sponsorship for this ballot & connection to index
        Sponsor[] sponsors;
        IxIface index;

        // deprecation flag - doesn't actually do anything besides signal that this contract is deprecated;
        bool deprecated;

        address ballotOwner;
        uint256 creationTs;
    }


    // ** Modifiers -- note, these are functions here to allow use as a lib
    function requireBallotClosed(DB storage db) internal view {
        require(now > BPackedUtils.packedToEndTime(db.packed), "!b-closed");
    }

    function requireBallotOpen(DB storage db) internal view {
        uint64 _n = uint64(now);
        uint64 startTs;
        uint64 endTs;
        (, startTs, endTs) = BPackedUtils.unpackAll(db.packed);
        require(_n >= startTs && _n < endTs, "!b-open");
        require(db.deprecated == false, "b-deprecated");
    }

    function requireBallotOwner(DB storage db) internal view {
        require(msg.sender == db.ballotOwner, "!b-owner");
    }

    function requireTesting(DB storage db) internal view {
        require(isTesting(BPackedUtils.packedToSubmissionBits(db.packed)), "!testing");
    }

    /* Library meta */

    function getVersion() external pure returns (uint) {
        // even though this is constant we want to make sure that it's actually
        // callable on Ethereum so we don't accidentally package the constant code
        // in with an SC using BBLib. This function _must_ be external.
        return BB_VERSION;
    }

    /* Functions */

    // "Constructor" function - init core params on deploy
    // timestampts are uint64s to give us plenty of room for millennia
    function init(DB storage db, bytes32 _specHash, uint256 _packed, IxIface ix, address ballotOwner, bytes16 extraData) external {
        require(db.specHash == bytes32(0), "b-exists");

        db.index = ix;
        db.ballotOwner = ballotOwner;

        uint64 startTs;
        uint64 endTs;
        uint16 sb;
        (sb, startTs, endTs) = BPackedUtils.unpackAll(_packed);

        bool _testing = isTesting(sb);
        if (_testing) {
            emit TestingEnabled();
        } else {
            require(endTs > now, "bad-end-time");

            // 0x1ff2 is 0001111111110010 in binary
            // by ANDing with subBits we make sure that only bits in positions 0,2,3,13,14,15
            // can be used. these correspond to the option flags at the top, and ETH ballots
            // that are enc'd or plaintext.
            require(sb & 0x1ff2 == 0, "bad-sb");

            // if we give bad submission bits (e.g. all 0s) then refuse to deploy ballot
            bool okaySubmissionBits = 1 == (isEthNoEnc(sb) ? 1 : 0) + (isEthWithEnc(sb) ? 1 : 0);
            require(okaySubmissionBits, "!valid-sb");

            // take the max of the start time provided and the blocks timestamp to avoid a DoS against recent token holders
            // (which someone might be able to do if they could set the timestamp in the past)
            startTs = startTs > now ? startTs : uint64(now);
        }
        require(_specHash != bytes32(0), "null-specHash");
        db.specHash = _specHash;

        db.packed = BPackedUtils.pack(sb, startTs, endTs);
        db.creationTs = now;

        if (extraData != bytes16(0)) {
            db.extraData = extraData;
        }

        emit CreatedBallot(db.specHash, startTs, endTs, sb);
    }

    /* sponsorship */

    function logSponsorship(DB storage db, uint value) internal {
        db.sponsors.push(Sponsor(msg.sender, value));
    }

    /* getters */

    function getVote(DB storage db, uint id) internal view returns (bytes32 voteData, address sender, bytes extra, uint castTs) {
        return (db.votes[id].voteData, address(db.votes[id].castTsAndSender), db.votes[id].extra, uint(db.votes[id].castTsAndSender) >> 160);
    }

    function getSequenceNumber(DB storage db, address voter) internal view returns (uint32) {
        return db.sequenceNumber[voter];
    }

    function getTotalSponsorship(DB storage db) internal view returns (uint total) {
        for (uint i = 0; i < db.sponsors.length; i++) {
            total += db.sponsors[i].amount;
        }
    }

    function getSponsor(DB storage db, uint i) external view returns (address sender, uint amount) {
        sender = db.sponsors[i].sender;
        amount = db.sponsors[i].amount;
    }

    /* ETH BALLOTS */

    function setSeqNumberMax(DB storage db) internal {
        // set the sequence number to max uint32 to disable proxy submitted ballots
        // after a voter submits a transaction personally - effectivley disables proxy
        // ballots. You can _always_ submit a new vote _personally_ with this scheme.
        if (db.sequenceNumber[msg.sender] != MAX_UINT32) {
            // using an IF statement here let's us save 4800 gas on repeat votes at the cost of 20k extra gas initially
            db.sequenceNumber[msg.sender] = MAX_UINT32;
        }
    }

    // Ballot submission
    // note: if USE_ENC then curve25519 keys should be generated by client for
    // each ballot (then thrown away).
    // the curve25519 PKs go in the extra param
    function submitVote(DB storage db, bytes32 voteData, bytes extra) external {
        _addVote(db, voteData, msg.sender, extra);
        setSeqNumberMax(db);
    }

    // this skips the checks performed by _addVote
    function submitVoteAlways(DB storage db, bytes32 voteData, bytes extra) external {
        _addVoteAlways(db, voteData, msg.sender, extra);
        setSeqNumberMax(db);
    }

    function submitProxyVote(DB storage db, bytes32[5] proxyReq, bytes extra) external returns (address voter) {
        return _submitProxyVote(db, proxyReq, extra, false);
    }

    function submitProxyVoteAlways(DB storage db, bytes32[5] proxyReq, bytes extra) external returns (address voter) {
        return _submitProxyVote(db, proxyReq, extra, true);
    }

    // Boundaries for constructing the msg we'll validate the signature of
    function _submitProxyVote(DB storage db, bytes32[5] proxyReq, bytes extra, bool submitAlways) internal returns (address voter) {
        // a proxy vote (where the vote is submitted (i.e. tx fee paid by someone else)
        // docs for datastructs: https://github.com/secure-vote/tokenvote/blob/master/Docs/DataStructs.md

        bytes32 r = proxyReq[0];
        bytes32 s = proxyReq[1];
        uint8 v = uint8(proxyReq[2][0]);
        // converting to uint248 will truncate the first byte, and we can then convert it to a bytes31.
        // we truncate the first byte because it's the `v` parm used above
        bytes31 proxyReq2 = bytes31(uint248(proxyReq[2]));
        // proxyReq[3] is ballotId - required for verifying sig but not used for anything else
        bytes32 ballotId = proxyReq[3];
        bytes32 voteData = proxyReq[4];

        // using abi.encodePacked is much cheaper than making bytes in other ways...
        bytes memory signed = abi.encodePacked(proxyReq2, ballotId, voteData, extra);
        bytes32 msgHash = keccak256(signed);
        // need to be sure we are signing the entire ballot and any extra data that comes with it
        voter = ecrecover(msgHash, v, r, s);

        // we need to make sure that this is the most recent vote the voter made, and that it has
        // not been seen before. NOTE: we've already validated the BBFarm namespace before this, so
        // we know it's meant for _this_ ballot.
        uint32 sequence = uint32(proxyReq2);  // last 4 bytes of proxyReq2 - the sequence number
        _proxyReplayProtection(db, voter, sequence);

        if (submitAlways) {
            _addVoteAlways(db, voteData, voter, extra);
        } else {
            _addVote(db, voteData, voter, extra);
        }
    }

    function _addVote(DB storage db, bytes32 voteData, address sender, bytes extra) internal returns (uint256 id) {
        requireBallotOpen(db);
        return _addVoteAlways(db, voteData, sender, extra);
    }

    function _addVoteAlways(DB storage db, bytes32 voteData, address sender, bytes extra) internal returns (uint256 id) {
        id = db.nVotesCast;
        db.votes[id].voteData = voteData;
        // pack the casting ts right next to the sender
        db.votes[id].castTsAndSender = bytes32(sender) ^ bytes32(now << 160);
        if (extra.length > 0) {
            db.votes[id].extra = extra;
        }
        db.nVotesCast += 1;
        emit SuccessfulVote(sender, id);
    }

    function _proxyReplayProtection(DB storage db, address voter, uint32 sequence) internal {
        // we want the replay protection sequence number to be STRICTLY MORE than what
        // is stored in the mapping. This means we can set sequence to MAX_UINT32 to disable
        // any future votes.
        require(db.sequenceNumber[voter] < sequence, "bad-sequence-n");
        db.sequenceNumber[voter] = sequence;
    }

    /* Admin */

    function setEndTime(DB storage db, uint64 newEndTime) external {
        uint16 sb;
        uint64 sTs;
        (sb, sTs,) = BPackedUtils.unpackAll(db.packed);
        db.packed = BPackedUtils.pack(sb, sTs, newEndTime);
    }

    function revealSeckey(DB storage db, bytes32 sk) internal {
        db.ballotEncryptionSeckey = sk;
        emit SeckeyRevealed(sk);
    }

    /* Submission Bits (Ballot Classifications) */

    // do (bits & SETTINGS_MASK) to get just operational bits (as opposed to testing or official flag)
    uint16 constant SETTINGS_MASK = 0xFFFF ^ USE_TESTING ^ IS_OFFICIAL ^ IS_BINDING;

    function isEthNoEnc(uint16 submissionBits) pure internal returns (bool) {
        return checkFlags(submissionBits, USE_ETH | USE_NO_ENC);
    }

    function isEthWithEnc(uint16 submissionBits) pure internal returns (bool) {
        return checkFlags(submissionBits, USE_ETH | USE_ENC);
    }

    function isOfficial(uint16 submissionBits) pure internal returns (bool) {
        return (submissionBits & IS_OFFICIAL) == IS_OFFICIAL;
    }

    function isBinding(uint16 submissionBits) pure internal returns (bool) {
        return (submissionBits & IS_BINDING) == IS_BINDING;
    }

    function isTesting(uint16 submissionBits) pure internal returns (bool) {
        return (submissionBits & USE_TESTING) == USE_TESTING;
    }

    function qualifiesAsCommunityBallot(uint16 submissionBits) pure internal returns (bool) {
        // if submissionBits AND any of the bits that make this _not_ a community
        // ballot is equal to zero that means none of those bits were active, so
        // it could be a community ballot
        return (submissionBits & (IS_BINDING | IS_OFFICIAL | USE_ENC)) == 0;
    }

    function checkFlags(uint16 submissionBits, uint16 expected) pure internal returns (bool) {
        // this should ignore ONLY the testing/flag bits - all other bits are significant
        uint16 sBitsNoSettings = submissionBits & SETTINGS_MASK;
        // then we want ONLY expected
        return sBitsNoSettings == expected;
    }
}
