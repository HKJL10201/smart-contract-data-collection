//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @title StarVoting contract interface.
/// @notice This contract is derived from @semaphore-protocol/contracts/interfaces/ISemaphoreVoting.sol.
interface IStarVoting {
    error Semaphore__CallerIsNotThePollCoordinator();
    error Semaphore__MerkleTreeDepthIsNotSupported();
    error Semaphore__PollHasAlreadyBeenStarted();
    error Semaphore__PollIsNotOngoing();
    error Semaphore__PollIsNotEnded();
    error Semaphore__YouAreUsingTheSameNillifierTwice();

    enum PollState {
        Created,
        Ongoing,
        Ended
    }

    struct Verifier {
        address contractAddress;
        uint256 merkleTreeDepth;
    }

    struct Poll {
        address coordinator;
        PollState state;
        bool isLivePoll;                              // Is the poll using asymmetric encryption
        bool isPrivate;                             // Is the poll private
        string encryptedPollInfo;                   // Encrypted Poll Details
        string encryptionKey;                       // Encryption Key
        string decryptionKey;                       // Decryption Key
        mapping(uint256 => bool) nullifierHashes;   // Prevent double voting
    }

    /// @dev Emitted when a new poll is created.
    /// @param pollId: Id of the poll.
    /// @param coordinator: Coordinator of the poll.
    event PollCreated(uint256 pollId, address indexed coordinator);

    /// @dev Emitted when a poll is started.
    /// @param pollId: Id of the poll.
    /// @param coordinator: Coordinator of the poll.
    /// @param encryptionKey: Key to encrypt the poll votes.
    event PollStarted(uint256 pollId, address indexed coordinator, string encryptionKey);

    /// @dev Emitted when a user votes on a poll.
    /// @param pollId: Id of the poll.
    /// @param vote: User encrypted vote.
    event VoteAdded(uint256 indexed pollId, string vote);

    /// @dev Emitted when a poll is ended.
    /// @param pollId: Id of the poll.
    /// @param coordinator: Coordinator of the poll.
    /// @param decryptionKey: Key to decrypt the poll votes.
    event PollEnded(uint256 pollId, address indexed coordinator, string decryptionKey);

    /// @dev Creates a poll and the associated Merkle tree/group.
    /// @param pollId: Id of the poll.
    /// @param coordinator: Coordinator of the poll.
    /// @param merkleTreeDepth: Depth of the tree.
    /// @param livePoll: True if the poll is live.
    function createPoll(uint256 pollId, address coordinator, uint256 merkleTreeDepth, bool livePoll, bool isPrivate, string calldata encryptedInfo) external;

    /// @dev Adds a voter to a poll.
    /// @param pollId: Id of the poll.
    /// @param identityCommitment: Identity commitment of the group member.
    function addVoter(uint256 pollId, uint256 identityCommitment) external;

    /// @dev Starts a pull and publishes the key to encrypt the votes.
    /// @param pollId: Id of the poll.
    /// @param encryptionKey: Key to encrypt poll votes.
    function startPoll(uint256 pollId, string calldata encryptionKey) external;

    /// @dev Casts an anonymous vote in a poll.
    /// @param vote: Encrypted vote.
    /// @param nullifierHash: Nullifier hash.
    /// @param pollId: Id of the poll.
    /// @param proof: Private zk-proof parameters.
    function castVote(string memory vote, uint256 nullifierHash, uint256 pollId, uint256[8] calldata proof) external;

    /// @dev Casts an anonymous vote in a poll.
    /// @param vote: Encrypted vote.
    /// @param nullifierHash: Nullifier hash.
    /// @param pollId: Id of the poll.
    /// @param proof: Private zk-proof parameters.
    // function castVote(uint256 vote, uint256 nullifierHash, uint256 pollId, uint256[8] calldata proof) external;

    /// @dev Ends a pull and publishes the key to decrypt the votes.
    /// @param pollId: Id of the poll.
    /// @param decryptionKey: Key to decrypt poll votes.
    function endPoll(uint256 pollId, string calldata decryptionKey) external;

    /// @dev Get Encrypted Poll Details
    /// @param pollId: Id of the poll.
    function getEncryptedPollInfo(uint256 pollId) external view returns (string memory);

    /// @dev Get Encryption Key of a poll.
    /// @param pollId: Id of the poll.
    function getEncryptionKey(uint256 pollId) external view returns (string memory);

    /// @dev Get Decryption Key of a poll.
    /// @param pollId: Id of the poll.
    function getDecryptionKey(uint256 pollId) external view returns (string memory);

    /// @dev Get isPrivate of a poll.
    /// @param pollId: Id of the poll.
    function isPrivatePoll(uint256 pollId) external view returns (bool);

    /// @dev Get isLive of a poll.
    /// @param pollId: Id of the poll.
    function isLivePoll(uint256 pollId) external view returns (bool);

    /// @dev Get the state of a poll.
    /// @param pollId: Id of the poll.
    function getPollState(uint256 pollId) external view returns (PollState);

    /// @dev Get the coordinator of a poll.
    /// @param pollId: Id of the poll.
    function getPollCoordinator(uint256 pollId) external view returns (address);
}
