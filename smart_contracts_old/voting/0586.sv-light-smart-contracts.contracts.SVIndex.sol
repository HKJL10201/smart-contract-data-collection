pragma solidity ^0.4.24;


//
// The Index by which democracies and ballots are tracked (and optionally deployed).
// Author: Max Kaye <max@secure.vote>
// version: v2.0.0
//


import { owned, upgradePtr, payoutAllC, controlledIface } from "./SVCommon.sol";
import "./hasVersion.sol";
import "./EnsOwnerProxy.sol";
import "./BPackedUtils.sol";
import "./BBLib.v7.sol";
import { BBFarmIface, BBFarmEvents } from "./BBFarm.sol";
import { CommAuctionIface } from "./CommunityAuction.sol";
import "./SVBallotConsts.sol";
import { IxBackendIface, ixBackendEvents } from "./SVIndexBackend.sol";
import { IxPaymentsIface, ixPaymentEvents } from "./SVPayments.sol";
import {CanReclaimToken} from "./CanReclaimToken.sol";


contract ixEvents {
    event PaymentMade(uint[2] valAndRemainder);
    event AddedBBFarm(uint8 bbFarmId);
    event SetBackend(bytes32 setWhat, address newSC);
    event DeprecatedBBFarm(uint8 bbFarmId);
    event CommunityBallot(bytes32 democHash, uint256 ballotId);
    event ManuallyAddedBallot(bytes32 democHash, uint256 ballotId, uint256 packed);
    // copied from BBFarm - unable to inherit from BBFarmEvents...
    event BallotCreatedWithID(uint ballotId);
    event BBFarmInit(bytes4 namespace);
}


// this should really be an interface or explictly abstract, but alas solidity is ... immature
contract IxIface is hasVersion,
                    ixPaymentEvents,
                    ixBackendEvents,
                    ixEvents,
                    SVBallotConsts,
                    owned,
                    CanReclaimToken,
                    upgradePtr,
                    payoutAllC {

    /* owner functions */
    function addBBFarm(BBFarmIface bbFarm) external returns (uint8 bbFarmId);
    function setABackend(bytes32 toSet, address newSC) external;
    function deprecateBBFarm(uint8 bbFarmId, BBFarmIface _bbFarm) external;

    /* global getters */
    function getPayments() external view returns (IxPaymentsIface);
    function getBackend() external view returns (IxBackendIface);
    function getBBFarm(uint8 bbFarmId) external view returns (BBFarmIface);
    function getBBFarmID(bytes4 bbNamespace) external view returns (uint8 bbFarmId);
    function getCommAuction() external view returns (CommAuctionIface);

    /* init a democ */
    function dInit(address defualtErc20, bool disableErc20OwnerClaim) external payable returns (bytes32);

    /* democ owner / editor functions */
    function setDEditor(bytes32 democHash, address editor, bool canEdit) external;
    function setDNoEditors(bytes32 democHash) external;
    function setDOwner(bytes32 democHash, address newOwner) external;
    function dOwnerErc20Claim(bytes32 democHash) external;
    function setDErc20(bytes32 democHash, address newErc20) external;
    function dAddCategory(bytes32 democHash, bytes32 categoryName, bool hasParent, uint parent) external;
    function dDeprecateCategory(bytes32 democHash, uint categoryId) external;
    function dUpgradeToPremium(bytes32 democHash) external;
    function dDowngradeToBasic(bytes32 democHash) external;
    function dSetArbitraryData(bytes32 democHash, bytes key, bytes value) external;
    function dSetCommunityBallotsEnabled(bytes32 democHash, bool enabled) external;
    function dDisableErc20OwnerClaim(bytes32 democHash) external;

    /* democ getters (that used to be here) should be called on either backend or payments directly */
    /* use IxLib for convenience functions from other SCs */

    /* ballot deployment */
    // only ix owner - used for adding past or special ballots
    function dAddBallot(bytes32 democHash, uint ballotId, uint256 packed) external;
    function dDeployCommunityBallot(bytes32 democHash, bytes32 specHash, bytes32 extraData, uint128 packedTimes) external payable;
    function dDeployBallot(bytes32 democHash, bytes32 specHash, bytes32 extraData, uint256 packed) external payable;
}


contract SVIndex is IxIface {
    uint256 constant VERSION = 2;

    // generated from: `address public owner;`
    bytes4 constant OWNER_SIG = 0x8da5cb5b;
    // generated from: `address public controller;`
    bytes4 constant CONTROLLER_SIG = 0xf77c4791;

    /* backend & other SC storage */

    IxBackendIface backend;
    IxPaymentsIface payments;
    EnsOwnerProxy public ensOwnerPx;
    BBFarmIface[] bbFarms;
    CommAuctionIface commAuction;
    // mapping from bbFarm namespace to bbFarmId
    mapping (bytes4 => uint8) bbFarmIdLookup;
    mapping (uint8 => bool) deprecatedBBFarms;

    //* MODIFIERS /

    modifier onlyDemocOwner(bytes32 democHash) {
        require(msg.sender == backend.getDOwner(democHash), "!d-owner");
        _;
    }

    modifier onlyDemocEditor(bytes32 democHash) {
        require(backend.isDEditor(democHash, msg.sender), "!d-editor");
        _;
    }

    /* FUNCTIONS */

    // constructor
    constructor( IxBackendIface _b
               , IxPaymentsIface _pay
               , EnsOwnerProxy _ensOwnerPx
               , BBFarmIface _bbFarm0
               , CommAuctionIface _commAuction
               ) payoutAllC(msg.sender) public {
        backend = _b;
        payments = _pay;
        ensOwnerPx = _ensOwnerPx;
        _addBBFarm(0x0, _bbFarm0);
        commAuction = _commAuction;
    }

    /* payoutAllC */

    function _getPayTo() internal view returns (address) {
        return payments.getPayTo();
    }

    /* UPGRADE STUFF */

    function doUpgrade(address nextSC) only_owner() not_upgraded() external {
        doUpgradeInternal(nextSC);
        backend.upgradeMe(nextSC);
        payments.upgradeMe(nextSC);
        ensOwnerPx.setAddr(nextSC);
        ensOwnerPx.upgradeMeAdmin(nextSC);
        commAuction.upgradeMe(nextSC);

        for (uint i = 0; i < bbFarms.length; i++) {
            bbFarms[i].upgradeMe(nextSC);
        }
    }

    function _addBBFarm(bytes4 bbNamespace, BBFarmIface _bbFarm) internal returns (uint8 bbFarmId) {
        uint256 bbFarmIdLong = bbFarms.length;
        require(bbFarmIdLong < 2**8, "too-many-farms");
        bbFarmId = uint8(bbFarmIdLong);

        bbFarms.push(_bbFarm);
        bbFarmIdLookup[bbNamespace] = bbFarmId;
        emit AddedBBFarm(bbFarmId);
    }

    // adding a new BBFarm
    function addBBFarm(BBFarmIface bbFarm) only_owner() external returns (uint8 bbFarmId) {
        bytes4 bbNamespace = bbFarm.getNamespace();

        require(bbNamespace != bytes4(0), "bb-farm-namespace");
        require(bbFarmIdLookup[bbNamespace] == 0 && bbNamespace != bbFarms[0].getNamespace(), "bb-namespace-used");

        bbFarmId = _addBBFarm(bbNamespace, bbFarm);
    }

    function setABackend(bytes32 toSet, address newSC) only_owner() external {
        emit SetBackend(toSet, newSC);
        if (toSet == bytes32("payments")) {
            payments = IxPaymentsIface(newSC);
        } else if (toSet == bytes32("backend")) {
            backend = IxBackendIface(newSC);
        } else if (toSet == bytes32("commAuction")) {
            commAuction = CommAuctionIface(newSC);
        } else {
            revert("404");
        }
    }

    function deprecateBBFarm(uint8 bbFarmId, BBFarmIface _bbFarm) only_owner() external {
        require(address(_bbFarm) != address(0));
        require(bbFarms[bbFarmId] == _bbFarm);
        deprecatedBBFarms[bbFarmId] = true;
        emit DeprecatedBBFarm(bbFarmId);
    }

    /* Getters for backends */

    function getPayments() external view returns (IxPaymentsIface) {
        return payments;
    }

    function getBackend() external view returns (IxBackendIface) {
        return backend;
    }

    function getBBFarm(uint8 bbFarmId) external view returns (BBFarmIface) {
        return bbFarms[bbFarmId];
    }

    function getBBFarmID(bytes4 bbNamespace) external view returns (uint8 bbFarmId) {
        return bbFarmIdLookup[bbNamespace];
    }

    function getCommAuction() external view returns (CommAuctionIface) {
        return commAuction;
    }

    //* GLOBAL INFO */

    function getVersion() external pure returns (uint256) {
        return VERSION;
    }

    //* DEMOCRACY FUNCTIONS - INDIVIDUAL */

    function dInit(address defaultErc20, bool disableErc20OwnerClaim) not_upgraded() external payable returns (bytes32) {
        require(msg.value >= payments.getMinWeiForDInit());
        bytes32 democHash = backend.dInit(defaultErc20, msg.sender, disableErc20OwnerClaim);
        payments.payForDemocracy.value(msg.value)(democHash);
        return democHash;
    }

    // admin methods

    function setDEditor(bytes32 democHash, address editor, bool canEdit) onlyDemocOwner(democHash) external {
        backend.setDEditor(democHash, editor, canEdit);
    }

    function setDNoEditors(bytes32 democHash) onlyDemocOwner(democHash) external {
        backend.setDNoEditors(democHash);
    }

    function setDOwner(bytes32 democHash, address newOwner) onlyDemocOwner(democHash) external {
        backend.setDOwner(democHash, newOwner);
    }

    function dOwnerErc20Claim(bytes32 democHash) external {
        address erc20 = backend.getDErc20(democHash);
        // test if we can call the erc20.owner() method, etc
        // also limit gas use to 3000 because we don't know what they'll do with it
        // during testing both owned and controlled could be called from other contracts for 2525 gas.
        if (erc20.call.gas(3000)(OWNER_SIG)) {
            require(msg.sender == owned(erc20).owner.gas(3000)(), "!erc20-owner");
        } else if (erc20.call.gas(3000)(CONTROLLER_SIG)) {
            require(msg.sender == controlledIface(erc20).controller.gas(3000)(), "!erc20-controller");
        } else {
            revert();
        }
        // now we are certain the sender deployed or controls the erc20
        backend.setDOwnerFromClaim(democHash, msg.sender);
    }

    function setDErc20(bytes32 democHash, address newErc20) onlyDemocOwner(democHash) external {
        backend.setDErc20(democHash, newErc20);
    }

    function dAddCategory(bytes32 democHash, bytes32 catName, bool hasParent, uint parent) onlyDemocEditor(democHash) external {
        backend.dAddCategory(democHash, catName, hasParent, parent);
    }

    function dDeprecateCategory(bytes32 democHash, uint catId) onlyDemocEditor(democHash) external {
        backend.dDeprecateCategory(democHash, catId);
    }

    function dUpgradeToPremium(bytes32 democHash) onlyDemocOwner(democHash) external {
        payments.upgradeToPremium(democHash);
    }

    function dDowngradeToBasic(bytes32 democHash) onlyDemocOwner(democHash) external {
        payments.downgradeToBasic(democHash);
    }

    function dSetArbitraryData(bytes32 democHash, bytes key, bytes value) external {
        if (msg.sender == backend.getDOwner(democHash)) {
            backend.dSetArbitraryData(democHash, key, value);
        } else if (backend.isDEditor(democHash, msg.sender)) {
            backend.dSetEditorArbitraryData(democHash, key, value);
        } else {
            revert();
        }
    }

    function dSetCommunityBallotsEnabled(bytes32 democHash, bool enabled) onlyDemocOwner(democHash) external {
        backend.dSetCommunityBallotsEnabled(democHash, enabled);
    }

    // this is one way only!
    function dDisableErc20OwnerClaim(bytes32 democHash) onlyDemocOwner(democHash) external {
        backend.dDisableErc20OwnerClaim(democHash);
    }

    /* Democ Getters - deprecated */
    // NOTE: the getters that used to live here just proxied to the backend.
    // this has been removed to reduce gas costs + size of Ix contract
    // For SCs you should use IxLib for convenience.
    // For Offchain use you should query the backend directly (via ix.getBackend())

    /* Add and Deploy Ballots */

    // manually add a ballot - only the owner can call this
    // WARNING - it's required that we make ABSOLUTELY SURE that
    // ballotId is valid and can resolve via the appropriate BBFarm.
    // this function _DOES NOT_ validate that everything else is done.
    function dAddBallot(bytes32 democHash, uint ballotId, uint256 packed)
                      only_owner()
                      external {

        _addBallot(democHash, ballotId, packed, false);
        emit ManuallyAddedBallot(democHash, ballotId, packed);
    }


    function _deployBallot(bytes32 democHash, bytes32 specHash, bytes32 extraData, uint packed, bool checkLimit, bool alreadySentTx) internal returns (uint ballotId) {
        require(BBLibV7.isTesting(BPackedUtils.packedToSubmissionBits(packed)) == false, "b-testing");

        // the most significant byte of extraData signals the bbFarm to use.
        uint8 bbFarmId = uint8(extraData[0]);
        require(deprecatedBBFarms[bbFarmId] == false, "bb-dep");
        BBFarmIface _bbFarm = bbFarms[bbFarmId];

        // anything that isn't a community ballot counts towards the basic limit.
        // we want to check in cases where
        // the ballot doesn't qualify as a community ballot
        // OR (the ballot qualifies as a community ballot
        //     AND the admins have _disabled_ community ballots).
        bool countTowardsLimit = checkLimit;
        bool performedSend;
        if (checkLimit) {
            uint64 endTime = BPackedUtils.packedToEndTime(packed);
            (countTowardsLimit, performedSend) = _basicBallotLimitOperations(democHash, _bbFarm);
            _accountOkayChecks(democHash, endTime);
        }

        if (!performedSend && msg.value > 0 && alreadySentTx == false) {
            // refund if we haven't send value anywhere (which might happen if someone accidentally pays us)
            doSafeSend(msg.sender, msg.value);
        }

        ballotId = _bbFarm.initBallot(
            specHash,
            packed,
            this,
            msg.sender,
            // we are certain that the first 8 bytes are for index use only.
            // truncating extraData like this means we can occasionally
            // save on gas. we need to use uint192 first because that will take
            // the _last_ 24 bytes of extraData.
            bytes24(uint192(extraData)));

        _addBallot(democHash, ballotId, packed, countTowardsLimit);
    }

    function dDeployCommunityBallot(bytes32 democHash, bytes32 specHash, bytes32 extraData, uint128 packedTimes) external payable {
        uint price = commAuction.getNextPrice(democHash);
        require(msg.value >= price, "!cb-fee");

        doSafeSend(payments.getPayTo(), price);
        doSafeSend(msg.sender, msg.value - price);

        bool canProceed = backend.getDCommBallotsEnabled(democHash) || !payments.accountInGoodStanding(democHash);
        require(canProceed, "!cb-enabled");

        uint256 packed = BPackedUtils.setSB(uint256(packedTimes), (USE_ETH | USE_NO_ENC));

        uint ballotId = _deployBallot(democHash, specHash, extraData, packed, false, true);
        commAuction.noteBallotDeployed(democHash);

        emit CommunityBallot(democHash, ballotId);
    }

    // only way a democ admin can deploy a ballot
    function dDeployBallot(bytes32 democHash, bytes32 specHash, bytes32 extraData, uint256 packed)
                          onlyDemocEditor(democHash)
                          external payable {

        _deployBallot(democHash, specHash, extraData, packed, true, false);
    }

    // internal logic around adding a ballot
    function _addBallot(bytes32 democHash, uint256 ballotId, uint256 packed, bool countTowardsLimit) internal {
        // backend handles events
        backend.dAddBallot(democHash, ballotId, packed, countTowardsLimit);
    }

    // check an account has paid up enough for this ballot
    function _accountOkayChecks(bytes32 democHash, uint64 endTime) internal view {
        // if the ballot is marked as official require the democracy is paid up to
        // some relative amount - exclude NFP accounts from this check
        uint secsLeft = payments.getSecondsRemaining(democHash);
        // must be positive due to ending in future check
        uint256 secsToEndTime = endTime - now;
        // require ballots end no more than twice the time left on the democracy
        require(secsLeft * 2 > secsToEndTime, "unpaid");
    }

    function _basicBallotLimitOperations(bytes32 democHash, BBFarmIface _bbFarm) internal returns (bool shouldCount, bool performedSend) {
        // if we're an official ballot and the democ is basic, ensure the democ
        // isn't over the ballots/mo limit
        if (payments.getPremiumStatus(democHash) == false) {
            uint nBallotsAllowed = payments.getBasicBallotsPer30Days();
            uint nBallotsBasicCounted = backend.getDCountedBasicBallotsN(democHash);

            // if the democ has less than nBallotsAllowed then it's guarenteed to be okay
            if (nBallotsAllowed > nBallotsBasicCounted) {
                // and we should count this ballot
                return (true, false);
            }

            // we want to check the creation timestamp of the nth most recent ballot
            // where n is the # of ballots allowed per month. Note: there isn't an off
            // by 1 error here because if 1 ballots were allowed per month then we'd want
            // to look at the most recent ballot, so nBallotsBasicCounted-1 in this case.
            // similarly, if X ballots were allowed per month we want to look at
            // nBallotsBasicCounted-X. There would thus be (X-1) ballots that are _more_
            // recent than the one we're looking for.
            uint earlyBallotId = backend.getDCountedBasicBallotID(democHash, nBallotsBasicCounted - nBallotsAllowed);
            uint earlyBallotTs = _bbFarm.getCreationTs(earlyBallotId);

            // if the earlyBallot was created more than 30 days in the past we should
            // count the new ballot
            if (earlyBallotTs < now - 30 days) {
                return (true, false);
            }

            // at this point it may be the case that we shouldn't allow the ballot
            // to be created. (It's an official ballot for a basic tier democracy
            // where the Nth most recent ballot was created within the last 30 days.)
            // We should now check for payment
            uint extraBallotFee = payments.getBasicExtraBallotFeeWei();
            require(msg.value >= extraBallotFee, "!extra-b-fee");

            // now that we know they've paid the fee, we should send Eth to `payTo`
            // and return the remainder.
            uint remainder = msg.value - extraBallotFee;
            doSafeSend(address(payments), extraBallotFee);
            doSafeSend(msg.sender, remainder);
            emit PaymentMade([extraBallotFee, remainder]);
            // only in this case (for basic) do we want to return false - don't count towards the
            // limit because it's been paid for here.
            return (false, true);

        } else {  // if we're premium we don't count ballots
            return (false, false);
        }
    }
}
