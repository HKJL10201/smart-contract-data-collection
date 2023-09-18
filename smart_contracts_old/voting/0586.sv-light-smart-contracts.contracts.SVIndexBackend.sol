pragma solidity 0.4.24;


/**
    Backend for the Index - all setters should be only_owner() or only_editors()
 */


import { permissioned, payoutAllC } from "./SVCommon.sol";
import "./BPackedUtils.sol";
import "./hasVersion.sol";


contract ixBackendEvents {
    event NewDemoc(bytes32 democHash);
    event ManuallyAddedDemoc(bytes32 democHash, address erc20);
    event NewBallot(bytes32 indexed democHash, uint ballotN);
    event DemocOwnerSet(bytes32 indexed democHash, address owner);
    event DemocEditorSet(bytes32 indexed democHash, address editor, bool canEdit);
    event DemocEditorsWiped(bytes32 indexed democHash);
    event DemocErc20Set(bytes32 indexed democHash, address erc20);
    event DemocDataSet(bytes32 indexed democHash, bytes32 keyHash);
    event DemocCatAdded(bytes32 indexed democHash, uint catId);
    event DemocCatDeprecated(bytes32 indexed democHash, uint catId);
    event DemocCommunityBallotsEnabled(bytes32 indexed democHash, bool enabled);
    event DemocErc20OwnerClaimDisabled(bytes32 indexed democHash);
    event DemocClaimed(bytes32 indexed democHash);
    event EmergencyDemocOwner(bytes32 indexed democHash, address newOwner);
}


// this should really be an interface, but alas solidity is ... immature
contract IxBackendIface is hasVersion, ixBackendEvents, permissioned, payoutAllC {
    /* global getters */
    function getGDemocsN() external view returns (uint);
    function getGDemoc(uint id) external view returns (bytes32);
    function getGErc20ToDemocs(address erc20) external view returns (bytes32[] democHashes);

    /* owner functions */
    function dAdd(bytes32 democHash, address erc20, bool disableErc20OwnerClaim) external;
    function emergencySetDOwner(bytes32 democHash, address newOwner) external;

    /* democ admin */
    function dInit(address defaultErc20, address initOwner, bool disableErc20OwnerClaim) external returns (bytes32 democHash);
    function setDOwner(bytes32 democHash, address newOwner) external;
    function setDOwnerFromClaim(bytes32 democHash, address newOwner) external;
    function setDEditor(bytes32 democHash, address editor, bool canEdit) external;
    function setDNoEditors(bytes32 democHash) external;
    function setDErc20(bytes32 democHash, address newErc20) external;
    function dSetArbitraryData(bytes32 democHash, bytes key, bytes value) external;
    function dSetEditorArbitraryData(bytes32 democHash, bytes key, bytes value) external;
    function dAddCategory(bytes32 democHash, bytes32 categoryName, bool hasParent, uint parent) external;
    function dDeprecateCategory(bytes32 democHash, uint catId) external;
    function dSetCommunityBallotsEnabled(bytes32 democHash, bool enabled) external;
    function dDisableErc20OwnerClaim(bytes32 democHash) external;

    /* actually add a ballot */
    function dAddBallot(bytes32 democHash, uint ballotId, uint256 packed, bool countTowardsLimit) external;

    /* global democ getters */
    function getDOwner(bytes32 democHash) external view returns (address);
    function isDEditor(bytes32 democHash, address editor) external view returns (bool);
    function getDHash(bytes13 prefix) external view returns (bytes32);
    function getDInfo(bytes32 democHash) external view returns (address erc20, address owner, uint256 nBallots);
    function getDErc20(bytes32 democHash) external view returns (address);
    function getDArbitraryData(bytes32 democHash, bytes key) external view returns (bytes value);
    function getDEditorArbitraryData(bytes32 democHash, bytes key) external view returns (bytes value);
    function getDBallotsN(bytes32 democHash) external view returns (uint256);
    function getDBallotID(bytes32 democHash, uint n) external view returns (uint ballotId);
    function getDCountedBasicBallotsN(bytes32 democHash) external view returns (uint256);
    function getDCountedBasicBallotID(bytes32 democHash, uint256 n) external view returns (uint256);
    function getDCategoriesN(bytes32 democHash) external view returns (uint);
    function getDCategory(bytes32 democHash, uint catId) external view returns (bool deprecated, bytes32 name, bool hasParent, uint parent);
    function getDCommBallotsEnabled(bytes32 democHash) external view returns (bool);
    function getDErc20OwnerClaimEnabled(bytes32 democHash) external view returns (bool);
}


contract SVIndexBackend is IxBackendIface {
    uint constant VERSION = 2;

    struct Democ {
        address erc20;
        address owner;
        bool communityBallotsDisabled;
        bool erc20OwnerClaimDisabled;
        uint editorEpoch;
        mapping (uint => mapping (address => bool)) editors;
        uint256[] allBallots;
        uint256[] includedBasicBallots;  // the IDs of official ballots

    }

    struct BallotRef {
        bytes32 democHash;
        uint ballotId;
    }

    struct Category {
        bool deprecated;
        bytes32 name;
        bool hasParent;
        uint parent;
    }

    struct CategoriesIx {
        uint nCategories;
        mapping(uint => Category) categories;
    }

    mapping (bytes32 => Democ) democs;
    mapping (bytes32 => CategoriesIx) democCategories;
    mapping (bytes13 => bytes32) democPrefixToHash;
    mapping (address => bytes32[]) erc20ToDemocs;
    bytes32[] democList;

    // allows democ admins to store arbitrary data
    // this lets us (for example) set particular keys to signal cerain
    // things to client apps s.t. the admin can turn them on and off.
    // arbitraryData[democHash][key]
    mapping (bytes32 => mapping (bytes32 => bytes)) arbitraryData;

    /* constructor */

    constructor() payoutAllC(msg.sender) public {
        // do nothing
    }

    /* base contract overloads */

    function _getPayTo() internal view returns (address) {
        return owner;
    }

    function getVersion() external pure returns (uint) {
        return VERSION;
    }

    /* GLOBAL INFO */

    function getGDemocsN() external view returns (uint) {
        return democList.length;
    }

    function getGDemoc(uint id) external view returns (bytes32) {
        return democList[id];
    }

    function getGErc20ToDemocs(address erc20) external view returns (bytes32[] democHashes) {
        return erc20ToDemocs[erc20];
    }

    /* DEMOCRACY ADMIN FUNCTIONS */

    function _addDemoc(bytes32 democHash, address erc20, address initOwner, bool disableErc20OwnerClaim) internal {
        democList.push(democHash);
        Democ storage d = democs[democHash];
        d.erc20 = erc20;
        if (disableErc20OwnerClaim) {
            d.erc20OwnerClaimDisabled = true;
        }
        // this should never trigger if we have a good security model - entropy for 13 bytes ~ 2^(8*13) ~ 10^31
        assert(democPrefixToHash[bytes13(democHash)] == bytes32(0));
        democPrefixToHash[bytes13(democHash)] = democHash;
        erc20ToDemocs[erc20].push(democHash);
        _setDOwner(democHash, initOwner);
        emit NewDemoc(democHash);
    }

    /* owner democ admin functions */

    function dAdd(bytes32 democHash, address erc20, bool disableErc20OwnerClaim) only_owner() external {
        _addDemoc(democHash, erc20, msg.sender, disableErc20OwnerClaim);
        emit ManuallyAddedDemoc(democHash, erc20);
    }

    /* Preferably for emergencies only */

    function emergencySetDOwner(bytes32 democHash, address newOwner) only_owner() external {
        _setDOwner(democHash, newOwner);
        emit EmergencyDemocOwner(democHash, newOwner);
    }

    /* user democ admin functions */

    function dInit(address defaultErc20, address initOwner, bool disableErc20OwnerClaim) only_editors() external returns (bytes32 democHash) {
        // generating the democHash in this way guarentees it'll be unique/hard-to-brute-force
        // (particularly because prevBlockHash and now are part of the hash)
        democHash = keccak256(abi.encodePacked(democList.length, blockhash(block.number-1), defaultErc20, now));
        _addDemoc(democHash, defaultErc20, initOwner, disableErc20OwnerClaim);
    }

    function _setDOwner(bytes32 democHash, address newOwner) internal {
        Democ storage d = democs[democHash];
        uint epoch = d.editorEpoch;
        d.owner = newOwner;
        // unset prev owner as editor - does little if one was not set
        d.editors[epoch][d.owner] = false;
        // make new owner an editor too
        d.editors[epoch][newOwner] = true;
        emit DemocOwnerSet(democHash, newOwner);
    }

    function setDOwner(bytes32 democHash, address newOwner) only_editors() external {
        _setDOwner(democHash, newOwner);
    }

    function setDOwnerFromClaim(bytes32 democHash, address newOwner) only_editors() external {
        Democ storage d = democs[democHash];
        // make sure that the owner claim is enabled (i.e. the disabled flag is false)
        require(d.erc20OwnerClaimDisabled == false, "!erc20-claim");
        // set owner and editor
        d.owner = newOwner;
        d.editors[d.editorEpoch][newOwner] = true;
        // disable the ability to claim now that it's done
        d.erc20OwnerClaimDisabled = true;
        emit DemocOwnerSet(democHash, newOwner);
        emit DemocClaimed(democHash);
    }

    function setDEditor(bytes32 democHash, address editor, bool canEdit) only_editors() external {
        Democ storage d = democs[democHash];
        d.editors[d.editorEpoch][editor] = canEdit;
        emit DemocEditorSet(democHash, editor, canEdit);
    }

    function setDNoEditors(bytes32 democHash) only_editors() external {
        democs[democHash].editorEpoch += 1;
        emit DemocEditorsWiped(democHash);
    }

    function setDErc20(bytes32 democHash, address newErc20) only_editors() external {
        democs[democHash].erc20 = newErc20;
        erc20ToDemocs[newErc20].push(democHash);
        emit DemocErc20Set(democHash, newErc20);
    }

    function dSetArbitraryData(bytes32 democHash, bytes key, bytes value) only_editors() external {
        bytes32 k = keccak256(key);
        arbitraryData[democHash][k] = value;
        emit DemocDataSet(democHash, k);
    }

    function dSetEditorArbitraryData(bytes32 democHash, bytes key, bytes value) only_editors() external {
        bytes32 k = keccak256(_calcEditorKey(key));
        arbitraryData[democHash][k] = value;
        emit DemocDataSet(democHash, k);
    }

    function dAddCategory(bytes32 democHash, bytes32 name, bool hasParent, uint parent) only_editors() external {
        uint catId = democCategories[democHash].nCategories;
        democCategories[democHash].categories[catId].name = name;
        if (hasParent) {
            democCategories[democHash].categories[catId].hasParent = true;
            democCategories[democHash].categories[catId].parent = parent;
        }
        democCategories[democHash].nCategories += 1;
        emit DemocCatAdded(democHash, catId);
    }

    function dDeprecateCategory(bytes32 democHash, uint catId) only_editors() external {
        democCategories[democHash].categories[catId].deprecated = true;
        emit DemocCatDeprecated(democHash, catId);
    }

    function dSetCommunityBallotsEnabled(bytes32 democHash, bool enabled) only_editors() external {
        democs[democHash].communityBallotsDisabled = !enabled;
        emit DemocCommunityBallotsEnabled(democHash, enabled);
    }

    function dDisableErc20OwnerClaim(bytes32 democHash) only_editors() external {
        democs[democHash].erc20OwnerClaimDisabled = true;
        emit DemocErc20OwnerClaimDisabled(democHash);
    }

    //* ADD BALLOT TO RECORD */

    function _commitBallot(bytes32 democHash, uint ballotId, uint256 packed, bool countTowardsLimit) internal {
        uint16 subBits;
        subBits = BPackedUtils.packedToSubmissionBits(packed);

        uint localBallotId = democs[democHash].allBallots.length;
        democs[democHash].allBallots.push(ballotId);

        // do this for anything that doesn't qualify as a community ballot
        if (countTowardsLimit) {
            democs[democHash].includedBasicBallots.push(ballotId);
        }

        emit NewBallot(democHash, localBallotId);
    }

    // what SVIndex uses to add a ballot
    function dAddBallot(bytes32 democHash, uint ballotId, uint256 packed, bool countTowardsLimit) only_editors() external {
        _commitBallot(democHash, ballotId, packed, countTowardsLimit);
    }

    /* democ getters */

    function getDOwner(bytes32 democHash) external view returns (address) {
        return democs[democHash].owner;
    }

    function isDEditor(bytes32 democHash, address editor) external view returns (bool) {
        Democ storage d = democs[democHash];
        // allow either an editor or always the owner
        return d.editors[d.editorEpoch][editor] || editor == d.owner;
    }

    function getDHash(bytes13 prefix) external view returns (bytes32) {
        return democPrefixToHash[prefix];
    }

    function getDInfo(bytes32 democHash) external view returns (address erc20, address owner, uint256 nBallots) {
        return (democs[democHash].erc20, democs[democHash].owner, democs[democHash].allBallots.length);
    }

    function getDErc20(bytes32 democHash) external view returns (address) {
        return democs[democHash].erc20;
    }

    function getDArbitraryData(bytes32 democHash, bytes key) external view returns (bytes) {
        return arbitraryData[democHash][keccak256(key)];
    }

    function getDEditorArbitraryData(bytes32 democHash, bytes key) external view returns (bytes) {
        return arbitraryData[democHash][keccak256(_calcEditorKey(key))];
    }

    function getDBallotsN(bytes32 democHash) external view returns (uint256) {
        return democs[democHash].allBallots.length;
    }

    function getDBallotID(bytes32 democHash, uint256 n) external view returns (uint ballotId) {
        return democs[democHash].allBallots[n];
    }

    function getDCountedBasicBallotsN(bytes32 democHash) external view returns (uint256) {
        return democs[democHash].includedBasicBallots.length;
    }

    function getDCountedBasicBallotID(bytes32 democHash, uint256 n) external view returns (uint256) {
        return democs[democHash].includedBasicBallots[n];
    }

    function getDCategoriesN(bytes32 democHash) external view returns (uint) {
        return democCategories[democHash].nCategories;
    }

    function getDCategory(bytes32 democHash, uint catId) external view returns (bool deprecated, bytes32 name, bool hasParent, uint256 parent) {
        deprecated = democCategories[democHash].categories[catId].deprecated;
        name = democCategories[democHash].categories[catId].name;
        hasParent = democCategories[democHash].categories[catId].hasParent;
        parent = democCategories[democHash].categories[catId].parent;
    }

    function getDCommBallotsEnabled(bytes32 democHash) external view returns (bool) {
        return !democs[democHash].communityBallotsDisabled;
    }

    function getDErc20OwnerClaimEnabled(bytes32 democHash) external view returns (bool) {
        return !democs[democHash].erc20OwnerClaimDisabled;
    }

    /* util for calculating editor key */

    function _calcEditorKey(bytes key) internal pure returns (bytes) {
        return abi.encodePacked("editor.", key);
    }
}
