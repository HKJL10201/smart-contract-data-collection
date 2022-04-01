pragma solidity ^0.4.24;


//
// The Index by which democracies and ballots are tracked (and optionally deployed).
// Author: Max Kaye <max@secure.vote>
// License: MIT
// version: v1.2.0 [WIP]
//


import { permissioned, payoutAllCSettable } from "./SVCommon.sol";
import "./hasVersion.sol";
import {CanReclaimToken} from "./CanReclaimToken.sol";


// local library just to give us a safe subtraction (usually for calculating time remaining)
library SafeMath {
    function subToZero(uint a, uint b) internal pure returns (uint) {
        if (a < b) {  // then (a - b) would overflow
            return 0;
        }
        return a - b;
    }
}


contract ixPaymentEvents {
    event UpgradedToPremium(bytes32 indexed democHash);
    event GrantedAccountTime(bytes32 indexed democHash, uint additionalSeconds, bytes32 ref);
    event AccountPayment(bytes32 indexed democHash, uint additionalSeconds);
    event SetCommunityBallotFee(uint amount);
    event SetBasicCentsPricePer30Days(uint amount);
    event SetPremiumMultiplier(uint8 multiplier);
    event DowngradeToBasic(bytes32 indexed democHash);
    event UpgradeToPremium(bytes32 indexed democHash);
    event SetExchangeRate(uint weiPerCent);
    event FreeExtension(bytes32 democHash);
    event SetBallotsPer30Days(uint amount);
    event SetFreeExtension(bytes32 democHash, bool hasFreeExt);
    event SetDenyPremium(bytes32 democHash, bool isPremiumDenied);
    event SetPayTo(address payTo);
    event SetMinorEditsAddr(address minorEditsAddr);
    event SetMinWeiForDInit(uint amount);
}


// this should really be an interface, but alas solidity is ... immature
contract IxPaymentsIface is hasVersion, ixPaymentEvents, permissioned, CanReclaimToken, payoutAllCSettable {
    /* in emergency break glass */
    function emergencySetOwner(address newOwner) external;

    /* financial calcluations */
    function weiBuysHowManySeconds(uint amount) public view returns (uint secs);
    function weiToCents(uint w) public view returns (uint);
    function centsToWei(uint c) public view returns (uint);

    /* account management */
    function payForDemocracy(bytes32 democHash) external payable;
    function doFreeExtension(bytes32 democHash) external;
    function downgradeToBasic(bytes32 democHash) external;
    function upgradeToPremium(bytes32 democHash) external;

    /* account status - getters */
    function accountInGoodStanding(bytes32 democHash) external view returns (bool);
    function getSecondsRemaining(bytes32 democHash) external view returns (uint);
    function getPremiumStatus(bytes32 democHash) external view returns (bool);
    function getFreeExtension(bytes32 democHash) external view returns (bool);
    function getAccount(bytes32 democHash) external view returns (bool isPremium, uint lastPaymentTs, uint paidUpTill, bool hasFreeExtension);
    function getDenyPremium(bytes32 democHash) external view returns (bool);

    /* admin utils for accounts */
    function giveTimeToDemoc(bytes32 democHash, uint additionalSeconds, bytes32 ref) external;

    /* admin setters global */
    function setPayTo(address) external;
    function setMinorEditsAddr(address) external;
    function setBasicCentsPricePer30Days(uint amount) external;
    function setBasicBallotsPer30Days(uint amount) external;
    function setPremiumMultiplier(uint8 amount) external;
    function setWeiPerCent(uint) external;
    function setFreeExtension(bytes32 democHash, bool hasFreeExt) external;
    function setDenyPremium(bytes32 democHash, bool isPremiumDenied) external;
    function setMinWeiForDInit(uint amount) external;

    /* global getters */
    function getBasicCentsPricePer30Days() external view returns(uint);
    function getBasicExtraBallotFeeWei() external view returns (uint);
    function getBasicBallotsPer30Days() external view returns (uint);
    function getPremiumMultiplier() external view returns (uint8);
    function getPremiumCentsPricePer30Days() external view returns (uint);
    function getWeiPerCent() external view returns (uint weiPerCent);
    function getUsdEthExchangeRate() external view returns (uint centsPerEth);
    function getMinWeiForDInit() external view returns (uint);

    /* payments stuff */
    function getPaymentLogN() external view returns (uint);
    function getPaymentLog(uint n) external view returns (bool _external, bytes32 _democHash, uint _seconds, uint _ethValue);
}


contract SVPayments is IxPaymentsIface {
    uint constant VERSION = 2;

    struct Account {
        bool isPremium;
        uint lastPaymentTs;
        uint paidUpTill;
        uint lastUpgradeTs;  // timestamp of the last time it was upgraded to premium
    }

    struct PaymentLog {
        bool _external;
        bytes32 _democHash;
        uint _seconds;
        uint _ethValue;
    }

    // this is an address that's only allowed to make minor edits
    // e.g. setExchangeRate, setDenyPremium, giveTimeToDemoc
    address public minorEditsAddr;

    // payment details
    uint basicCentsPricePer30Days = 125000; // $1250/mo
    uint basicBallotsPer30Days = 10;
    uint8 premiumMultiplier = 5;
    uint weiPerCent = 0.000016583747 ether;  // $603, 4th June 2018

    uint minWeiForDInit = 1;  // minimum 1 wei - match existing behaviour in SVIndex

    mapping (bytes32 => Account) accounts;
    PaymentLog[] payments;

    // can set this on freeExtension democs to deny them premium upgrades
    mapping (bytes32 => bool) denyPremium;
    // this is used for non-profits or organisations that have perpetual licenses, etc
    mapping (bytes32 => bool) freeExtension;


    /* BREAK GLASS IN CASE OF EMERGENCY */
    // this is included here because something going wrong with payments is possibly
    // the absolute worst case. Note: does this have negligable benefit if the other
    // contracts are compromised? (e.g. by a leaked privkey)
    address public emergencyAdmin;
    function emergencySetOwner(address newOwner) external {
        require(msg.sender == emergencyAdmin, "!emergency-owner");
        owner = newOwner;
    }
    /* END BREAK GLASS */


    constructor(address _emergencyAdmin) payoutAllCSettable(msg.sender) public {
        emergencyAdmin = _emergencyAdmin;
        assert(_emergencyAdmin != address(0));
    }

    /* base SCs */

    function getVersion() external pure returns (uint) {
        return VERSION;
    }

    function() payable public {
        _getPayTo().transfer(msg.value);
    }

    function _modAccountBalance(bytes32 democHash, uint additionalSeconds) internal {
        uint prevPaidTill = accounts[democHash].paidUpTill;
        if (prevPaidTill < now) {
            prevPaidTill = now;
        }

        accounts[democHash].paidUpTill = prevPaidTill + additionalSeconds;
        accounts[democHash].lastPaymentTs = now;
    }

    /* Financial Calculations */

    function weiBuysHowManySeconds(uint amount) public view returns (uint) {
        uint centsPaid = weiToCents(amount);
        // multiply by 10**18 to ensure we make rounding errors insignificant
        uint monthsOffsetPaid = ((10 ** 18) * centsPaid) / basicCentsPricePer30Days;
        uint secondsOffsetPaid = monthsOffsetPaid * (30 days);
        uint additionalSeconds = secondsOffsetPaid / (10 ** 18);
        return additionalSeconds;
    }

    function weiToCents(uint w) public view returns (uint) {
        return w / weiPerCent;
    }

    function centsToWei(uint c) public view returns (uint) {
        return c * weiPerCent;
    }

    /* account management */

    function payForDemocracy(bytes32 democHash) external payable {
        require(msg.value > 0, "need to send some ether to make payment");

        uint additionalSeconds = weiBuysHowManySeconds(msg.value);

        if (accounts[democHash].isPremium) {
            additionalSeconds /= premiumMultiplier;
        }

        if (additionalSeconds >= 1) {
            _modAccountBalance(democHash, additionalSeconds);
        }
        payments.push(PaymentLog(false, democHash, additionalSeconds, msg.value));
        emit AccountPayment(democHash, additionalSeconds);

        _getPayTo().transfer(msg.value);
    }

    function doFreeExtension(bytes32 democHash) external {
        require(freeExtension[democHash], "!free");
        uint newPaidUpTill = now + 60 days;
        accounts[democHash].paidUpTill = newPaidUpTill;
        emit FreeExtension(democHash);
    }

    function downgradeToBasic(bytes32 democHash) only_editors() external {
        require(accounts[democHash].isPremium, "!premium");
        accounts[democHash].isPremium = false;
        // convert premium minutes to basic
        uint paidTill = accounts[democHash].paidUpTill;
        uint timeRemaining = SafeMath.subToZero(paidTill, now);
        // if we have time remaining: convert it
        if (timeRemaining > 0) {
            // prevent accounts from downgrading if they have time remaining
            // and upgraded less than 24hrs ago
            require(accounts[democHash].lastUpgradeTs < (now - 24 hours), "downgrade-too-soon");
            timeRemaining *= premiumMultiplier;
            accounts[democHash].paidUpTill = now + timeRemaining;
        }
        emit DowngradeToBasic(democHash);
    }

    function upgradeToPremium(bytes32 democHash) only_editors() external {
        require(denyPremium[democHash] == false, "upgrade-denied");
        require(!accounts[democHash].isPremium, "!basic");
        accounts[democHash].isPremium = true;
        // convert basic minutes to premium minutes
        uint paidTill = accounts[democHash].paidUpTill;
        uint timeRemaining = SafeMath.subToZero(paidTill, now);
        // if we have time remaning then convert it - otherwise don't need to do anything
        if (timeRemaining > 0) {
            timeRemaining /= premiumMultiplier;
            accounts[democHash].paidUpTill = now + timeRemaining;
        }
        accounts[democHash].lastUpgradeTs = now;
        emit UpgradedToPremium(democHash);
    }

    /* account status - getters */

    function accountInGoodStanding(bytes32 democHash) external view returns (bool) {
        return accounts[democHash].paidUpTill >= now;
    }

    function getSecondsRemaining(bytes32 democHash) external view returns (uint) {
        return SafeMath.subToZero(accounts[democHash].paidUpTill, now);
    }

    function getPremiumStatus(bytes32 democHash) external view returns (bool) {
        return accounts[democHash].isPremium;
    }

    function getFreeExtension(bytes32 democHash) external view returns (bool) {
        return freeExtension[democHash];
    }

    function getAccount(bytes32 democHash) external view returns (bool isPremium, uint lastPaymentTs, uint paidUpTill, bool hasFreeExtension) {
        isPremium = accounts[democHash].isPremium;
        lastPaymentTs = accounts[democHash].lastPaymentTs;
        paidUpTill = accounts[democHash].paidUpTill;
        hasFreeExtension = freeExtension[democHash];
    }

    function getDenyPremium(bytes32 democHash) external view returns (bool) {
        return denyPremium[democHash];
    }

    /* admin utils for accounts */

    function giveTimeToDemoc(bytes32 democHash, uint additionalSeconds, bytes32 ref) owner_or(minorEditsAddr) external {
        _modAccountBalance(democHash, additionalSeconds);
        payments.push(PaymentLog(true, democHash, additionalSeconds, 0));
        emit GrantedAccountTime(democHash, additionalSeconds, ref);
    }

    /* admin setters global */

    function setPayTo(address newPayTo) only_owner() external {
        _setPayTo(newPayTo);
        emit SetPayTo(newPayTo);
    }

    function setMinorEditsAddr(address a) only_owner() external {
        minorEditsAddr = a;
        emit SetMinorEditsAddr(a);
    }

    function setBasicCentsPricePer30Days(uint amount) only_owner() external {
        basicCentsPricePer30Days = amount;
        emit SetBasicCentsPricePer30Days(amount);
    }

    function setBasicBallotsPer30Days(uint amount) only_owner() external {
        basicBallotsPer30Days = amount;
        emit SetBallotsPer30Days(amount);
    }

    function setPremiumMultiplier(uint8 m) only_owner() external {
        premiumMultiplier = m;
        emit SetPremiumMultiplier(m);
    }

    function setWeiPerCent(uint wpc) owner_or(minorEditsAddr) external {
        weiPerCent = wpc;
        emit SetExchangeRate(wpc);
    }

    function setFreeExtension(bytes32 democHash, bool hasFreeExt) owner_or(minorEditsAddr) external {
        freeExtension[democHash] = hasFreeExt;
        emit SetFreeExtension(democHash, hasFreeExt);
    }

    function setDenyPremium(bytes32 democHash, bool isPremiumDenied) owner_or(minorEditsAddr) external {
        denyPremium[democHash] = isPremiumDenied;
        emit SetDenyPremium(democHash, isPremiumDenied);
    }

    function setMinWeiForDInit(uint amount) owner_or(minorEditsAddr) external {
        minWeiForDInit = amount;
        emit SetMinWeiForDInit(amount);
    }

    /* global getters */

    function getBasicCentsPricePer30Days() external view returns (uint) {
        return basicCentsPricePer30Days;
    }

    function getBasicExtraBallotFeeWei() external view returns (uint) {
        return centsToWei(basicCentsPricePer30Days / basicBallotsPer30Days);
    }

    function getBasicBallotsPer30Days() external view returns (uint) {
        return basicBallotsPer30Days;
    }

    function getPremiumMultiplier() external view returns (uint8) {
        return premiumMultiplier;
    }

    function getPremiumCentsPricePer30Days() external view returns (uint) {
        return _premiumPricePer30Days();
    }

    function _premiumPricePer30Days() internal view returns (uint) {
        return uint(premiumMultiplier) * basicCentsPricePer30Days;
    }

    function getWeiPerCent() external view returns (uint) {
        return weiPerCent;
    }

    function getUsdEthExchangeRate() external view returns (uint) {
        // this returns cents per ether
        return 1 ether / weiPerCent;
    }

    function getMinWeiForDInit() external view returns (uint) {
        return minWeiForDInit;
    }

    /* payments stuff */

    function getPaymentLogN() external view returns (uint) {
        return payments.length;
    }

    function getPaymentLog(uint n) external view returns (bool _external, bytes32 _democHash, uint _seconds, uint _ethValue) {
        _external = payments[n]._external;
        _democHash = payments[n]._democHash;
        _seconds = payments[n]._seconds;
        _ethValue = payments[n]._ethValue;
    }
}
