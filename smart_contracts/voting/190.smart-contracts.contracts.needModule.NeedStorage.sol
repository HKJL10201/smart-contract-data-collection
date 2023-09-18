// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract NeedStorage is Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");

    address public treasuryAddress;
    address public timeLockAddress;

    enum NeedTypeEnum {
        SERVICE,
        PRODUCT
    }

    enum NeedKindEnum {
        COMMON,
        PERSONAL,
        UNIQUE
    }

    enum ContributorRoles {
        SOCIAL_WORKER,
        PURCHASER,
        AUDITOR
    }

    enum VirtualFamilyRoles {
        VIRTUAL_MOM_ROLE,
        VIRTUAL_DAD_ROLE,
        VIRTUAL_AUNT_ROLE,
        VIRTUAL_UNCLE_ROLE
    }

    struct Contributor {
        uint256 userId;
        ContributorRoles sayRole;
        uint256 ngoId;
        address wallet;
    }

    struct FamilyMember {
        uint256 userId;
        VirtualFamilyRoles familyRole;
        address wallet;
    }

    struct Difficaulty {
        uint8 creation;
        uint8 audit;
        uint8 logistic;
        uint8 communityPrority;
    }

    struct NeedDetails {
        Difficaulty difficaulty;
        mapping(address => uint256) vFamiliesShares;
        uint256 socialWorkerShare;
        uint256 auditorShare;
        uint256 purchaserShare;
        uint256 reward;
    }

    struct Need {
        uint256 needId;
        uint256 ngoId;
        uint256 childId;
        uint256 providerId;
        Contributor socialWorker;
        Contributor auditor;
        Contributor purchaser;
        mapping(address => FamilyMember) participants;
        uint256 mintValue;
        address minter;
        NeedDetails details;
    }

    /**
     * @dev signature: From a Family member signing a transaction using the existing signature from social worker and need data
     */
    struct FinalVoucher {
        uint256 needId;
        uint256[] vFamiliesIds;
        uint256 mintValue;
        // wallets
        address swWallet;
        address auditorWallet;
        address purchaserWallet;
        address[] vFamiliesWallet; // virtual families who participated
        //signatures
        bytes swSignature; // social worker signature
        bytes signature;
        string content;
    }

    FinalVoucher public voucher;

    mapping(uint256 => Need) private needByToken;
    mapping(NeedTypeEnum => mapping(NeedKindEnum => Difficaulty))
        public difficaulties;

    /**
     * @dev Sets Grant admin role to timeLock
     */
    constructor(address _timeLockAddress) {
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(TIMELOCK_ROLE, _timeLockAddress);
        _grantRole(PAUSER_ROLE, _timeLockAddress);
        timeLockAddress = _timeLockAddress;
    }

    function updateTrasury(
        address _treasuryAddress
    ) external onlyRole(TIMELOCK_ROLE) {
        require(!paused(), "PAUSED");
        treasuryAddress = _treasuryAddress;
    }

    function updateDifficaulty(
        Difficaulty memory _difficaulty,
        NeedKindEnum _kind,
        NeedTypeEnum _type
    ) external onlyRole(TIMELOCK_ROLE) returns (Difficaulty memory) {
        require(!paused(), "PAUSED");
        Difficaulty memory difficaulty = difficaulties[_type][_kind];
        if (difficaulty.creation <= 0) {
            difficaulty = Difficaulty({
                creation: _difficaulty.creation,
                audit: _difficaulty.audit,
                logistic: _difficaulty.logistic,
                communityPrority: _difficaulty.communityPrority
            });
            difficaulties[_type][_kind] = _difficaulty;
        } else {
            difficaulty = difficaulties[_type][_kind];
            difficaulty.creation = _difficaulty.creation;
            difficaulty.audit = _difficaulty.audit;
            difficaulty.logistic = _difficaulty.logistic;
            difficaulty.communityPrority = _difficaulty.communityPrority;
        }
        return difficaulties[_type][_kind];
    }

    function getTresaryAddress() public view {
        treasuryAddress;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}
