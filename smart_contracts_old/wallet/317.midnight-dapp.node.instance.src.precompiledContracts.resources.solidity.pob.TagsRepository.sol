pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
import "../Constants.sol";
import "../IConstantsRepository.sol";
import "./ITagsRepository.sol";

/// @title Smart Contract used to store PoB Tags
contract TagsRepository is ITagsRepository {
    struct Tag {
        bytes32 mmrRoot;
        uint256 roundHeight;
    }

    event TagAccepted(uint8 chainId, bytes32 mmrRoot, uint256 roundHeight);

    // Saves all the decided tags
    mapping (uint8 => Tag[]) private tags;

    // votedTag[chain][federationMember]
    mapping (uint8 => mapping (address => Tag)) private votedTag;

    // We keep locally the set of all federation members who have voted. Ideally we would get this information from the
    // ConstantsRepository, however calling an external contract that returns a dynamic data type (address[] in this
    // case) is not supported in Homestead.
    mapping (address => bool) private allVotersSet;
    address[] private allVoters;

    /// Votes for a Tag in a specified source blockchain
    /// @param chainId Source ChainId
    /// @param mmrRoot Merkle Mountain Range Root Hash to be used to claim for burned tokens
    /// @param roundHeight number of blocks the tag involve (it include blocks [0, roundHeight])
    function vote(uint8 chainId, bytes32 mmrRoot, uint256 roundHeight) override external {
        IConstantsRepository constantsRepository = IConstantsRepository(Constants.constantsRepository());
        require(constantsRepository.isValidFederationNodeKey(msg.sender), "Only a federation node can create a source blockchain Tag");
        require(constantsRepository.isValidChainId(chainId), "Invalid chainId");

        if (!allVotersSet[msg.sender]) {
            allVoters.push(msg.sender);
            allVotersSet[msg.sender] = true;
        }

        if (tags[chainId].length > 0) {
            require(tags[chainId][tags[chainId].length - 1].roundHeight < roundHeight, "Cannot vote for a past round");
        }
        votedTag[chainId][msg.sender] = Tag(mmrRoot, roundHeight);
        Tag storage thisTag = votedTag[chainId][msg.sender];
        uint majority = constantsRepository.federationSize() / 2 + 1;
        uint votesForThisRoot = 0;
        for (uint i = 0; i < allVoters.length; ++i) {
            Tag storage otherTag = votedTag[chainId][allVoters[i]];
            if (thisTag.mmrRoot == otherTag.mmrRoot && thisTag.roundHeight == otherTag.roundHeight) {
                ++votesForThisRoot;
            }
        }
        if (votesForThisRoot >= majority) {
            tags[chainId].push(thisTag);
            emit TagAccepted(chainId, thisTag.mmrRoot, thisTag.roundHeight);
        }
    }

    /// Returns true if the given mmrRoot is a valid Tag for the chain with chainId
    /// @param chainId Source blockchain Chain Invalid
    /// @param mmrRoot Merkle Mountain Range Root to look for
    function isRecentMMRRoot(uint8 chainId, bytes32 mmrRoot) override external view returns (bool) {
        IConstantsRepository constantsRepository = IConstantsRepository(Constants.constantsRepository());
        require(constantsRepository.isValidChainId(chainId), "Invalid chainId");

        for (uint i = 0; i < tags[chainId].length; i++) {
            if (tags[chainId][i].mmrRoot == mmrRoot) {
                return true;
            }
        }
        return false;
    }

    // Given a chain id, returns federation latest tagged block number
    /// @param chainId Source blockchain Chain Invalid
    function getRoundHeightForLastTag(uint8 chainId) override public view returns (uint256) {
        IConstantsRepository constantsRepository = IConstantsRepository(Constants.constantsRepository());
        require(constantsRepository.isValidChainId(chainId), "Invalid chainId");

        if (tags[chainId].length > 0) {
            return tags[chainId][tags[chainId].length - 1].roundHeight;
        } else {
            return 0;
        }
    }
}
