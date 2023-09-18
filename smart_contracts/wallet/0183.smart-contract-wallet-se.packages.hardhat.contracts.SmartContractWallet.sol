//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./SmartContractWalletFactory.sol";
import "hardhat/console.sol";

/// @title A Smart Contract Wallet with Social Recovery
/// @author Leonardo Sanchez
/// @notice Basic implementation of Vitalik's "Why we need wide adoption of social recovery wallets" post
/// @dev This contract has not been audited, it's just for edutaiment purposes only
contract SmartContractWallet {
    SmartContractWalletFactory public smartContractWalletFactory;

    /// Wallet Basics
    address public owner;
    uint256 public balance;
    uint256 public nonce;
    uint256 public chainId;

    /// Wallet Guardians
    bytes32[] public guardiansAddressHashes;
    address[] public revealedGuardiansAddress;
    uint256 public guardiansRequired;
    mapping(bytes32 => bool) public isGuardian;
    mapping(bytes32 => uint256) public guardianHashToRemovalTimestamp;

    /// Wallet Recovery
    bool public inRecovery;
    uint256 public currentRecoveryRound;
    address public proposedOwner;
    struct Recovery {
        address proposedOwner;
        uint256 recoveryRound;
        bool usedInExecuteRecovery;
    }
    mapping(address => Recovery) public guardianToRecovery;
    mapping(address => bool) public isSupporter;

    /// Wallet Events
    event TransactionExecuted(
        uint256 nonce,
        address indexed target,
        uint256 value,
        bytes data,
        bytes result
    );

    // Keep track of guardians added and removed for interface actions
    event Guardian(bytes32 indexed guardian, bool added);

    // Guardian Management
    event GuardianRemovalQueued(bytes32 indexed guardianHash);
    event GuardianRemoved(
        bytes32 indexed oldGuardianHash,
        bytes32 indexed newGuardianHash
    );
    event GuardinshipTransferred(
        address indexed from,
        bytes32 indexed newGuardianHash
    );

    /// Recovery Events
    event RecoveryInitiated(
        address indexed by,
        address newProposedOwner,
        uint256 indexed round
    );
    event RecoverySupported(
        address by,
        address newProposedOwner,
        uint256 indexed round
    );
    event RecoveryCancelled(address by, uint256 indexed round);
    event RecoveryExecuted(
        address oldOwner,
        address newOwner,
        uint256 indexed round
    );

    /// Guardian Reveal
    event GuardianRevealed(
        bytes32 indexed guardianHash,
        address indexed guardianAddr,
        string email
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyGuardian() {
        require(
            isGuardian[keccak256(abi.encodePacked(msg.sender))],
            "Only guardian"
        );
        _;
    }

    modifier nonZeroGuardians(uint256 _guardiansRequired) {
        require(_guardiansRequired > 0, "Must be non-zero guardians");
        _;
    }

    modifier onlyInRecovery() {
        require(inRecovery, "Wallet is not in recovery mode");
        _;
    }

    modifier notInRecovery() {
        require(!inRecovery, "Wallet is in recovery mode");
        _;
    }

    error Disagreement__OnNewOwner();

    /// @notice Initializes the Smart Contract Wallet with a set of Guardians and a minimum required Guardians to fullfiil a Recovery
    /// @param _chainId ChainId of the deployed wallet
    /// @param _owner Initial owner of the wallet
    /// @param _guardianAddressHashes Initial Guardian Address Hashes calculated in the front-end
    /// @param _guardiansRequired Minimum required Guardians to fullfiil a Recovery
    /// @param _factory Factory Address
    constructor(
        uint256 _chainId,
        address _owner,
        bytes32[] memory _guardianAddressHashes,
        uint256 _guardiansRequired,
        address _factory
    ) payable nonZeroGuardians(_guardiansRequired) {
        smartContractWalletFactory = SmartContractWalletFactory(_factory);
        require(
            _guardiansRequired <= _guardianAddressHashes.length,
            "Number of guardians too high"
        );

        for (uint256 i = 0; i < _guardianAddressHashes.length; i++) {
            require(
                !isGuardian[_guardianAddressHashes[i]],
                "Duplicate guardian"
            );
            isGuardian[_guardianAddressHashes[i]] = true;
            guardiansAddressHashes.push(_guardianAddressHashes[i]);
            emit Guardian(
                _guardianAddressHashes[i],
                isGuardian[_guardianAddressHashes[i]]
            );
        }

        guardiansRequired = _guardiansRequired;
        chainId = _chainId;
        owner = _owner;
    }

    /// @notice Execute Transfers / Contract Calls
    /// @dev The Alexandr N. Tetearing algorithm could increase precision
    /// @param _target target of the transaction
    /// @param _value value of the transaction
    /// @param _data payload of the transaction
    /// @return bytes Transaction
    function executeTransaction(
        address payable _target,
        uint256 _value,
        bytes memory _data
    ) external onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _target.call{value: _value}(
            _data
        );
        require(success, "Transaction Failed");
        nonce++;
        emit TransactionExecuted(nonce - 1, _target, _value, _data, result);
        return result;
    }

    /// @notice Initiate a Guardian Removal
    /// @dev Change the time to a higher value to protect the wallet from unwanted guardian chages
    /// @param _guardianAddressHash Address to queue for removal
    function initiateGuardianRemoval(bytes32 _guardianAddressHash)
        external
        onlyOwner
    {
        // verify that the hash actually corresponds to a guardian
        require(isGuardian[_guardianAddressHash], "Not a guardian");

        // removal delay for demo purposes 60 seconds, should be in days
        guardianHashToRemovalTimestamp[_guardianAddressHash] =
            block.timestamp +
            60 seconds;
        emit GuardianRemovalQueued(_guardianAddressHash);
    }

    /// @notice Execute the Guardian Removal after the time has pass
    /// @dev The emit Wallet from the factory is used to keep track of the wallet
    /// @param _oldGuardianHash target of the transaction
    /// @param _newGuardianHash value of the transaction
    function executeGuardianRemoval(
        bytes32 _oldGuardianHash,
        bytes32 _newGuardianHash
    ) external onlyOwner {
        require(
            guardianHashToRemovalTimestamp[_oldGuardianHash] > 0,
            "Guardian isn't queued for removal"
        );
        require(
            guardianHashToRemovalTimestamp[_oldGuardianHash] <= block.timestamp,
            "Time delay has not passed"
        );

        guardianHashToRemovalTimestamp[_oldGuardianHash] = 0;

        _removeGuardianList(_oldGuardianHash);
        isGuardian[_newGuardianHash] = true;
        guardiansAddressHashes.push(_newGuardianHash);

        emit GuardianRemoved(_oldGuardianHash, _newGuardianHash);
        emit Guardian(_oldGuardianHash, isGuardian[_oldGuardianHash]);
        emit Guardian(_newGuardianHash, isGuardian[_newGuardianHash]);
        smartContractWalletFactory.emitWallet(
            address(this),
            owner,
            guardiansAddressHashes,
            guardiansRequired
        );
    }

    /// @notice Cancel the Guardian Removal
    /// @dev Reset to zero the timer
    /// @param _guardianHash Guardian hash we want to cancel the removal
    function cancelGuardianRemoval(bytes32 _guardianHash) external onlyOwner {
        guardianHashToRemovalTimestamp[_guardianHash] = 0;
    }

    /// @notice Transfer the Guardianship
    /// @dev Reset to zero the timer
    /// @param _newGuardianHash New Guardian hash
    function transferGuardianship(bytes32 _newGuardianHash)
        external
        onlyGuardian
        notInRecovery
    {
        require(
            guardianHashToRemovalTimestamp[
                keccak256(abi.encodePacked(msg.sender))
            ] == 0,
            "guardian queueud for removal, cannot transfer guardianship"
        );
        _removeGuardianList(keccak256(abi.encodePacked(msg.sender)));
        isGuardian[_newGuardianHash] = true;
        guardiansAddressHashes.push(_newGuardianHash);

        emit Guardian(
            keccak256(abi.encodePacked(msg.sender)),
            isGuardian[keccak256(abi.encodePacked(msg.sender))]
        );
        emit Guardian(_newGuardianHash, isGuardian[_newGuardianHash]);
        emit GuardinshipTransferred(msg.sender, _newGuardianHash);
        smartContractWalletFactory.emitWallet(
            address(this),
            owner,
            guardiansAddressHashes,
            guardiansRequired
        );
    }

    /// @notice Pop a Guardian from the list
    /// @param _oldGuardian target of the transaction
    function _removeGuardianList(bytes32 _oldGuardian) private {
        isGuardian[_oldGuardian] = false;
        uint256 guardiansLength = guardiansAddressHashes.length;
        bytes32[] memory poppedGuardians = new bytes32[](
            guardiansAddressHashes.length
        );
        for (uint256 i = guardiansLength - 1; i >= 0; i--) {
            if (guardiansAddressHashes[i] != _oldGuardian) {
                poppedGuardians[i] = guardiansAddressHashes[i];
                guardiansAddressHashes.pop();
            } else {
                guardiansAddressHashes.pop();
                for (uint256 j = i; j < guardiansLength - 1; j++) {
                    guardiansAddressHashes.push(poppedGuardians[j]);
                }
                return;
            }
        }
    }

    /// @notice Reveal the identity (ex. owner dies)
    /// @param _email Email for contacting Guardians
    function revealGuardianIdentity(string calldata _email)
        external
        onlyGuardian
    {
        emit GuardianRevealed(
            keccak256(abi.encodePacked(msg.sender)),
            msg.sender,
            _email
        );
    }

    /// @notice Initiate the recovery process by proposing a new owner
    /// @param _proposedOwner New proposed owner
    function initiateRecovery(address _proposedOwner)
        external
        onlyGuardian
        notInRecovery
    {
        proposedOwner = _proposedOwner;
        currentRecoveryRound++;
        guardianToRecovery[msg.sender] = Recovery(
            _proposedOwner,
            currentRecoveryRound,
            false
        );
        revealedGuardiansAddress.push(msg.sender);
        isSupporter[msg.sender] = true;
        inRecovery = true;
        emit RecoveryInitiated(
            msg.sender,
            _proposedOwner,
            currentRecoveryRound
        );
    }

    /// @notice Support the recovery process
    /// @param _proposedOwner New proposed owner
    function supportRecovery(address _proposedOwner)
        external
        onlyGuardian
        onlyInRecovery
    {
        require(!isSupporter[msg.sender], "Sender is already a supporter");
        guardianToRecovery[msg.sender] = Recovery(
            _proposedOwner,
            currentRecoveryRound,
            false
        );
        revealedGuardiansAddress.push(msg.sender);
        emit RecoverySupported(
            msg.sender,
            _proposedOwner,
            currentRecoveryRound
        );
    }

    /// @notice Cancel the recovery process by the owner if it was started without consent
    function cancelRecovery() external onlyOwner onlyInRecovery {
        inRecovery = false;
        emit RecoveryCancelled(msg.sender, currentRecoveryRound);
    }

    /// @notice Finalize the Recovery Process
    function executeRecovery() external onlyGuardian onlyInRecovery {
        require(
            revealedGuardiansAddress.length >= guardiansRequired,
            "More guardians required to transfer ownership"
        );

        for (uint256 i = 0; i < revealedGuardiansAddress.length; i++) {
            Recovery memory recovery = guardianToRecovery[
                revealedGuardiansAddress[i]
            ];

            if (recovery.proposedOwner != proposedOwner) {
                revert Disagreement__OnNewOwner();
            }

            guardianToRecovery[revealedGuardiansAddress[i]]
                .usedInExecuteRecovery = true;
            isSupporter[revealedGuardiansAddress[i]] = false;
        }

        inRecovery = false;
        address _oldOwner = owner;
        owner = proposedOwner;
        delete revealedGuardiansAddress;
        emit RecoveryExecuted(_oldOwner, owner, currentRecoveryRound);
        delete proposedOwner;
        smartContractWalletFactory.emitWallet(
            address(this),
            owner,
            guardiansAddressHashes,
            guardiansRequired
        );
    }

    /// @notice Reset the last round when there is a proposedowner mismatch
    function resetRound() external onlyGuardian onlyInRecovery {
        for (uint256 i = 0; i < revealedGuardiansAddress.length; i++) {
            Recovery memory recovery = guardianToRecovery[
                revealedGuardiansAddress[i]
            ];

            if (recovery.proposedOwner != proposedOwner) {
                delete revealedGuardiansAddress;
                delete proposedOwner;
                _resetIsSupporter();
                inRecovery = false;
                break;
            }
        }
    }

    /// @notice Reset the isSupporter mapping
    function _resetIsSupporter() private {
        for (uint256 i = 0; i < revealedGuardiansAddress.length; i++) {
            isSupporter[revealedGuardiansAddress[i]] = false;
        }
    }

    receive() external payable {
        balance += msg.value;
    }
}
