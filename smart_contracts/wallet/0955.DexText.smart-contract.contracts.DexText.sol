// SPDX-License-Identifier: GNU General Public License v3.0 (GNU GPLv3)
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title Encrypted Messaging Contract
/// @author Your Name
/// @notice This contract allows users to send and receive encrypted messages.
/// @dev This contract uses OpenZeppelin upgradeable contracts for security and upgradeability.
contract EncryptedMessaging is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using AddressUpgradeable for address payable;

    /// @dev Represents a single message.
    struct Message {
        address sender;
        address recipient;
        bytes32 ipfsHash;
        uint256 replyTo;
        bool readStatus;
        uint256 readTimestamp;
    }

    mapping(uint256 => Message) private _messages;
    mapping(address => EnumerableSetUpgradeable.UintSet) private _userMessages;
    uint256 private _nextMessageId;

    /// @dev Emitted when a message is sent.
    event MessageSent(uint256 indexed messageId, address indexed sender, address indexed recipient, bytes32 ipfsHash, uint256 replyTo, uint256 timestamp);
    /// @dev Emitted when a message is received.
    event MessageReceived(uint256 indexed messageId, address indexed sender, address indexed recipient);
    /// @dev Emitted when a message is read.
    event MessageRead(uint256 indexed messageId, address indexed reader, uint256 timestamp);
    /// @dev Emitted when the contract is paused.
    event ContractPaused(address indexed pauser);
    /// @dev Emitted when the contract is unpaused.
    event ContractUnpaused(address indexed unpauser);

    /// @notice Initializes the contract.
    function initialize() external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
    }

    /// @dev Authorizes an upgrade.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice Sends a message.
    /// @dev The message is stored in IPFS and only the hash is stored on-chain.
    /// @param recipient The address of the recipient.
    /// @param ipfsHash The IPFS hash of the message.
    /// @param replyTo The ID of the message this is a reply to.
    function sendMessage(address recipient, bytes32 ipfsHash, uint256 replyTo) external payable whenNotPaused {
        require(recipient != address(0) && recipient != address(this), "Invalid recipient address");

        uint256 parentThreadId = replyTo != 0 ? _messages[replyTo].replyTo : 0;

        require(replyTo == 0 || _messages[replyTo].sender == msg.sender || _messages[replyTo].recipient == msg.sender, "Invalid replyTo message ID");

        _messages[_nextMessageId] = Message(msg.sender, recipient, ipfsHash, parentThreadId, false, 0);

        _userMessages[msg.sender].add(_nextMessageId);
        _userMessages[recipient].add(_nextMessageId);

        emit MessageSent(_nextMessageId, msg.sender, recipient, ipfsHash, replyTo, block.timestamp);
        emit MessageReceived(_nextMessageId, msg.sender, recipient);

        if (msg.value > 0) {
            payable(recipient).sendValue(msg.value);
        }

        _nextMessageId++;
    }

    /// @notice Marks a message as read.
    /// @dev Only the recipient of the message can mark it as read.
    /// @param messageId The ID of the message to mark as read.
    function markAsRead(uint256 messageId) external whenNotPaused {
        Message storage message = _messages[messageId];

        require(msg.sender == message.recipient, "Caller must be recipient of the message");

        message.readStatus = true;
        message.readTimestamp = block.timestamp;

        emit MessageRead(messageId, msg.sender, block.timestamp);
    }

    /// @notice Gets a message.
    /// @dev Returns the details of a message.
    /// @param messageId The ID of the message to get.
    /// @return The details of the message.
    function getMessage(uint256 messageId) external view returns (address, address, bytes32, uint256, bool, uint256) {
        Message storage message = _messages[messageId];

        return (message.sender, message.recipient, message.ipfsHash, message.replyTo, message.readStatus, message.readTimestamp);
    }

    /// @notice Gets multiple messages.
    /// @dev Returns an array of messages.
    /// @param startIndex The start index.
    /// @param endIndex The end index.
    /// @return An array of messages.
    function getMessages(uint256 startIndex, uint256 endIndex) external view returns (Message[] memory) {
        require(startIndex < endIndex && endIndex <= _nextMessageId, "Invalid indices");

        Message[] memory messages = new Message[](endIndex - startIndex);

        for (uint256 i = startIndex; i < endIndex; i++) {
            messages[i - startIndex] = _messages[i];
        }

        return messages;
    }

    /// @notice Gets the IDs of all messages sent or received by a user.
    /// @dev Returns an array of message IDs.
    /// @param user The address of the user.
    /// @return An array of message IDs.
    function getUserMessageIds(address user) external view returns (uint256[] memory) {
        EnumerableSetUpgradeable.UintSet storage userSet = _userMessages[user];
        uint256[] memory ids = new uint256[](userSet.length());

        for (uint256 i = 0; i < userSet.length(); i++) {
            ids[i] = userSet.at(i);
        }

       
    return ids;
}

/// @notice Gets the total number of messages.
/// @dev Returns the total number of messages.
/// @return The total number of messages.
function getMessageCount() external view returns (uint256) {
    return _nextMessageId;
}

/// @notice Pauses the contract.
/// @dev Only the owner can pause the contract.
function pause() external onlyOwner {
    _pause();
    emit ContractPaused(msg.sender);
}

/// @notice Unpauses the contract.
/// @dev Only the owner can unpause the contract.
function unpause() external onlyOwner {
    _unpause();
    emit ContractUnpaused(msg.sender);
}
}
