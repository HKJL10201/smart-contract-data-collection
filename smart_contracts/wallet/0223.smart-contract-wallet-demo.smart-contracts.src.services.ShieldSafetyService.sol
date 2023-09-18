// SPDX-License-Identifier: MIT only

pragma solidity ^0.8.0;

import "./BaseService.sol";
import "../IWallet.sol";
import "./utils/SignatureDecoder.sol";

/**
 * @title ShieldSafetyService
 * @dev Service to manage the security aspects of a CoinMaster Wallet.
 * @notice This is a singleton contract to manage all CoinMaster Wallets based on storage data
*/
contract ShieldSafetyService is BaseService, SignatureDecoder {

    struct GuardianDetails {
        uint256 dateAdded;
        uint256 votingWeight; // Additional voting weight given to the guardian. Default = 0, 1 means the guardian's vote counts twice for a recovery against other guardians.
    }

    struct Guardians {
        // address represents the wallet of the guardian and maps to its details
        mapping(address => GuardianDetails) guardian;
        uint256 totalGuardians;
        uint256 threshold;
    }

    // wallet address => guardians  (ex. guardians[wallet].guardian[_guardianWallet].additionalVotingWeight = 1)
    mapping(address => Guardians) internal guardians;

    constructor() BaseService("ShieldSafetyService") {}

    modifier onlyGuardian(address _wallet) {
        require(isGuardian(_wallet, msg.sender), "Must be a guardian");
        _;
    }

    function isGuardian(address _wallet, address _addr) public view returns (bool) {
        return guardians[_wallet].guardian[_addr].votingWeight > 0;
    }
    
    function lockWallet(address _wallet) external onlyWalletOwnerOrSelf(_wallet) onlyWhenUnlocked(_wallet) {
        IWallet(_wallet).lock(true);
    }

    function unlock(address _wallet) external onlyWalletOwnerOrSelf(_wallet) onlyWhenLocked(_wallet) {
        IWallet(_wallet).lock(false);
    }

    function totalGuardians(address _wallet) public view returns (uint256) {
        return guardians[_wallet].totalGuardians;
    }

    function setGuardianThreshold(address _wallet, uint256 _threshold) external onlyWalletOwnerOrSelf(_wallet) {
        require(_threshold > 0, "Threshold must be greater than 0");
        require(_threshold <= totalGuardians(_wallet), "Threshold must be less than or equal to total guardians");
        guardians[_wallet].threshold = _threshold;
    }   

    function getGuardianThreshold(address _wallet) public view returns (uint256) {
        return guardians[_wallet].threshold;
    }

    function addGuardians(address _wallet, address[] calldata _guardians, uint256[] calldata _weights, uint256 _threshold) external onlyWalletOwnerOrSelf(_wallet) {
        require(_threshold > 0, "Threshold must be greater than 0");
        for (uint256 i = 0; i < _guardians.length; i++) {
            address guardian = _guardians[i];
            require(!isGuardian(_wallet, guardian), "Guardian already added");
            require(_weights[i] > 0, "Weight must be greater than 0");
            guardians[_wallet].guardian[guardian].votingWeight = _weights[i];
            guardians[_wallet].guardian[guardian].dateAdded = block.timestamp;
            guardians[_wallet].totalGuardians++;
        }
        guardians[_wallet].threshold = _threshold;
        // Todo: emit event
    }

    function adjustGuardianWeight(address _wallet, address _guardian, uint256 _newWeight) external onlyWalletOwnerOrSelf(_wallet) {
        require(isGuardian(_wallet, _guardian), "Guardian not added");
        require(_newWeight > 0, "Weight must be greater than 0");
        guardians[_wallet].guardian[_guardian].votingWeight = _newWeight;
    }

    function removeGuardian(address _wallet, address _guardian) external onlyWalletOwnerOrSelf(_wallet) {
        require(isGuardian(_wallet, _guardian), "Guardian not added");
        delete guardians[_wallet].guardian[_guardian];
        guardians[_wallet].totalGuardians--;
        // Todo: emit event
    }

    /**
    * @dev Function for a guardian to recover a wallet by transfering ownership to a new address
    */
    function guardianRecover(
        address _wallet, 
        address _newOwner, 
        bytes memory _signatures, 
        bytes32 _dataHash
        ) external onlyGuardian(_wallet) {
        require(totalGuardians(_wallet) > 0, "No guardians");
        // ToDo: add check that dataHash is expected
        uint256 requiredSignatures = _signatures.length / 65;
        require(_signatures.length % 65 == 0, "Invalid signatures length");
        address[] memory signers = SignatureDecoder.getSigners(_dataHash, _signatures,requiredSignatures);
        uint256 voteCount = 0;
        for (uint256 i = 0; i < signers.length; i++) {
            require(isGuardian(_wallet, signers[i]), "Signatures were not from guardians or were formatted improperly");
            GuardianDetails memory guardian = guardians[_wallet].guardian[signers[i]];
            voteCount += guardian.votingWeight;
        }
        if (voteCount >= getGuardianThreshold(_wallet)) {
            IWallet(_wallet).transferOwner(_newOwner);
        } else {
            revert("Not enough votes");
        }
    }
}