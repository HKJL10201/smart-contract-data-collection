pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

// SignatureVerification library to verify the owner's signature.
library SignatureVerification {
    function verify(
        address _signer,
        address _owner,
        address _operator,
        bool _approved,
        uint256 _nonce,
        uint256 _validUntil,
        bytes memory _signature
    ) internal pure returns (bool) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(_owner, _operator, _approved, _nonce, _validUntil)
        );
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);

        return ECDSA.recover(ethSignedMessageHash, _signature) == _signer;
    }
}

// IApproveForAllWithSignature interface to declare the approveForAllWithSignature function.
interface IApproveForAllWithSignature {
    function approveForAllWithSignature(
        address _owner,
        address _operator,
        bool _approved,
        uint256 _nonce,
        uint256 _validUntil,
        bytes memory _signature
    ) external;
}

// ApproveForAllWithSignature contract implementing the IApproveForAllWithSignature interface.
// The contract also includes role-based access control, pausability, and upgradeability features.
contract ApproveForAllWithSignature is
    IApproveForAllWithSignature,
    AccessControl,
    Pausable,
    UUPSUpgradeable
{
    // Declare constants for role identifiers.
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Mapping to store nonces for each token owner.
    mapping(address => uint256) private _nonces;

    // Initialize the contract with the appropriate roles and permissions.
    function initialize() public initializer {
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
    }

    // approveForAllWithSignature function implementation.
    // Allows token owners to approve or revoke the approval of an operator to manage their tokens.
    function approveForAllWithSignature(
        address _owner,
        address _operator,
        bool _approved,
        uint256 _nonce,
        uint256 _validUntil,
        bytes memory _signature
    ) external override whenNotPaused {
        // Verify that the signature is valid and the nonce matches the owner's current nonce.
        require(
            SignatureVerification.verify(
                msg.sender,
                _owner,
                _operator,
                _approved,
                _nonce,
                _validUntil,
                _signature
            ),
            "Invalid signature"
        );

        // Verify that the signature has not expired.
        require(block.number <= _validUntil, "Signature expired");

        // Update the nonce for the owner.
        _nonces[_owner] = _nonce + 1;

        // Call the setApprovalForAll function of the appropriate token contract (ERC721 or ERC1155).
        try IERC721(_owner).setApprovalForAll(_operator, _approved) {} catch {
            IERC1155(_owner).setApprovalForAll(_operator, _approved);
        }

        // Emit an ApprovalForAll event.
        emit ApprovalForAll(_owner, _operator, _approved);
    }

    // Function to get the nonce for a given token owner.
    function getNonce(address _owner) external view returns (uint256) {
        return _nonces[_owner];
    }

    // Pause the contract.
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    // Unpause the contract.
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // Function to upgrade the contract.
    function _authorizeUpgrade(address) internal override onlyRole(UPGRADER_ROLE) {}

    // Event to emit when an operator is approved or disapproved for all tokens.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}
