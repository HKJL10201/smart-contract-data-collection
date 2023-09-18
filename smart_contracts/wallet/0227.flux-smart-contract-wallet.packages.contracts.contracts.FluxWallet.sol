// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

/**
 ** This is inspired by
 ** https://vitalik.ca/general/2021/01/11/recovery.html
 ** This impementation is extended from
 ** https://github.com/verumlotus/social-recovery-wallet/blob/main/src/Wallet.sol
 **/

import "@account-abstraction/contracts/samples/SimpleWallet.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

// implemented features of flux-wallet
import "./features/DeadManSwitch.sol";
import "./features/SocialRecover.sol";
import "./features/SessionManagement.sol";
import "./features/AccessGrants.sol";

interface IVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory input
    ) external view returns (bool);
}

contract FluxWallet is
    ERC165,
    IERC1271,
    SimpleWallet,
    DeadManSwitch,
    SocialRecover,
    SessionManagement
{
    /************************************************
     *  STORAGE
     ***********************************************/

    /// @notice true if hash of guardian address, else false
    mapping(address => bool) public isGuardian;

    /// @notice stores the guardian threshold
    uint256 public threshold;

    /// @notice true iff wallet is in recovery mode
    bool public inRecovery;

    /// @notice round of recovery we're in
    uint256 public currRecoveryRound;

    //for otp verification
    address public verifierAddr;
    uint256 public root;
    uint256 public lastUsedTime = 0;

    /// @notice struct used for bookkeeping during recovery mode
    /// @dev trival struct but can be extended in future (when building for malicious guardians
    /// or when owner key is compromised)
    struct Recovery {
        address proposedOwner;
        uint256 recoveryRound; // recovery round in which this recovery struct was created
        bool usedInExecuteRecovery; // set to true when we see this struct in RecoveryExecute
    }

    /// @notice mapping from guardian address to most recent Recovery struct created by them
    mapping(address => Recovery) public guardianToRecovery;

    uint256 public constant version = 1;

    /************************************************
     *  MODIFIERS & EVENTS
     ***********************************************/

    modifier onlyGuardian() {
        require(isGuardian[msg.sender], "only guardian");
        _;
    }

    modifier notInRecovery() {
        require(!inRecovery, "wallet is in recovery mode");
        _;
    }

    modifier onlyInRecovery() {
        require(inRecovery, "wallet is not in recovery mode");
        _;
    }

    /// @notice emit when recovery initiated
    event RecoveryInitiated(
        address indexed by,
        address newProposedOwner,
        uint256 indexed round
    );

    /// @notice emit when recovery supported
    event RecoverySupported(
        address by,
        address newProposedOwner,
        uint256 indexed round
    );

    /// @notice emit when recovery is cancelled
    event RecoveryCancelled(address by, uint256 indexed round);

    /// @notice emit when recovery is executed
    event RecoveryExecuted(
        address oldOwner,
        address newOwner,
        uint256 indexed round
    );

    constructor(
        IEntryPoint anEntryPoint,
        address anOwner,
        uint _root
    ) SimpleWallet(anEntryPoint, anOwner) {
        root = _root;
        verifierAddr = 0x9Bd0782Cc9C70a57aCAc290077a7e0fc8A4E7C4B;
    }

    modifier isValidProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory input
    ) {
        require(
            IVerifier(verifierAddr).verifyProof(a, b, c, input),
            "invalid proof"
        );
        require(input[0] == root, "invalid root");
        require(input[1] > lastUsedTime, "old OTP");
        _;
        lastUsedTime = input[1];
    }

    function setMerkleRootAndVerifier(
        uint256 _root,
        address _verifier
    ) external {
        root = _root;
        verifierAddr = _verifier;
    }

    function setGuardians(
        address[] memory guardians,
        uint256 _threshold
    ) public {
        require(_threshold <= guardians.length, "threshold too high");
        for (uint256 i = 0; i < guardians.length; i++) {
            require(!isGuardian[guardians[i]], "duplicate guardian");
            isGuardian[guardians[i]] = true;
        }
        threshold = _threshold;
    }

    /**
     * @notice Allows a guardian to initiate a wallet recovery
     * Wallet cannot already be in recovery mode
     * @param _proposedOwner - address of the new propsoed owner
     */
    function initiateRecovery(
        address _proposedOwner
    ) external onlyGuardian notInRecovery {
        // we are entering a new recovery round
        currRecoveryRound++;
        guardianToRecovery[msg.sender] = Recovery(
            _proposedOwner,
            currRecoveryRound,
            false
        );
        inRecovery = true;
        emit RecoveryInitiated(msg.sender, _proposedOwner, currRecoveryRound);
    }

    /**
     * @notice Allows a guardian to support a wallet recovery
     * Wallet must already be in recovery mode
     * @param _proposedOwner - address of the proposed owner;
     */
    function supportRecovery(
        address _proposedOwner
    ) external onlyGuardian onlyInRecovery {
        guardianToRecovery[msg.sender] = Recovery(
            _proposedOwner,
            currRecoveryRound,
            false
        );
        emit RecoverySupported(msg.sender, _proposedOwner, currRecoveryRound);
    }

    /**
     * @notice Allows the owner to cancel a wallet recovery (assuming they recovered private keys)
     * Wallet must already be in recovery mode
     * @dev TODO: allow guardians to cancel recovery
     * (need more than one guardian else trivially easy for one malicious guardian to DoS a wallet recovery)
     */
    function cancelRecovery() external onlyOwner onlyInRecovery {
        inRecovery = false;
        emit RecoveryCancelled(msg.sender, currRecoveryRound);
    }

    /**
     * @notice Allows a guardian to execute a wallet recovery and set a newOwner
     * Wallet must already be in recovery mode
     * @param newOwner - the new owner of the wallet
     * @param guardianList - list of addresses of guardians that have voted for this newOwner
     */
    function executeRecovery(
        address newOwner,
        address[] calldata guardianList
    ) external onlyGuardian onlyInRecovery {
        // Need enough guardians to agree on same newOwner
        require(
            guardianList.length >= threshold,
            "more guardians required to transfer ownership"
        );

        // Let's verify that all guardians agreed on the same newOwner in the same round
        for (uint256 i = 0; i < guardianList.length; i++) {
            // cache recovery struct in memory
            Recovery memory recovery = guardianToRecovery[guardianList[i]];

            require(
                recovery.recoveryRound == currRecoveryRound,
                "round mismatch"
            );
            require(
                recovery.proposedOwner == newOwner,
                "disagreement on new owner"
            );
            require(
                !recovery.usedInExecuteRecovery,
                "duplicate guardian used in recovery"
            );

            // set field to true in storage, not memory
            guardianToRecovery[guardianList[i]].usedInExecuteRecovery = true;
        }

        inRecovery = false;
        address _oldOwner = owner;
        owner = newOwner;
        emit RecoveryExecuted(_oldOwner, newOwner, currRecoveryRound);
    }

    function isValidSignature(
        bytes32 _hash,
        bytes calldata _signature
    ) external view override returns (bytes4) {
        address recovered = ECDSA.recover(_hash, _signature);
        if (recovered == owner) {
            return type(IERC1271).interfaceId;
        } else {
            return 0xffffffff;
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC1271).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function testTransfer(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory input,
        address to,
        uint256 value
    ) public isValidProof(a, b, c, input) {
        payable(to).transfer(value);
    }

    function zkProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory d,
        uint256 value,
        address dest
    ) external {
        testTransfer(a, b, c, d, dest, value);
    }

    function sendTransaction(
        address payable dest,
        uint256 amount
    ) external onlyOwner {
        dest.transfer(amount);
    }
}
