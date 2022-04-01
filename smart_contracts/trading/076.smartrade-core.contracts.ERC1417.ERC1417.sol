// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "./IERC1417.sol";

/**
 * @title ERC1417 Poll Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-1417
 */
contract ERC1417 is Context, ERC165, IERC1417 {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Represents a single voter.
    struct Voter {
        uint256 weight;   // weight is accumulated by delegation
        bool voted;       // if true, that person already voted
        address delegate; // person delegated to
        uint256 vote;     // index of the voted proposal
    }

    // A type for a single proposal.
    struct Proposal {
        bytes32 name;       // short name (up to 32 bytes)
        uint256 voteCount;  // number of accumulated votes
        uint256 voteWeight; // cumulative vote weight
    }

    // This declares a state variable that stores a `Voter` struct for each possible address.
    mapping(address => Voter) private _voters;

    // Poll voters
    EnumerableSet.AddressSet private _pollVoters;

    // A dynamically-sized array of `Proposal` structs.
    Proposal[] private _proposals;

    // Poll name
    string private _name;

    // Poll type
    string private _type;

    /*
     *     bytes4(keccak256('vote(uint256)')) == 0x0121b93f
     *     bytes4(keccak256('revokeVote()')) == 0x43c14b22
     *     bytes4(keccak256('getProposals()')) == 0x62564c48
     *     bytes4(keccak256('canVote(address)')) == 0xadfaa72e
     *     bytes4(keccak256('allVote()')) == 0xf74928b5
     *     bytes4(keccak256('getVoteTally(uint256)')) == 0x79cc9351
     *     bytes4(keccak256('getVoterCount(uint256)')) == 0xe92e5c34
     *     bytes4(keccak256('calculateVoteWeight(address)')) == 0x3fbd4216
     *     bytes4(keccak256('winningProposal()')) == 0x609ff1bd
     *     bytes4(keccak256('getVoterBaseLogic()')) == 0xbaf8f441
     *     bytes4(keccak256('getStartTime()')) == 0xc828371e
     *     bytes4(keccak256('getEndTime()')) == 0x439f5ac2
     *     bytes4(keccak256('getProtocolAddresses()')) == 0xa1774da0
     *     bytes4(keccak256('getVoteTallies()')) == 0xca656e5a
     *     bytes4(keccak256('getVoterCounts()')) == 0x44a09e65
     *     bytes4(keccak256('getVoterBaseDenominator()')) == 0x9e35bf13
     *
     *     => 0x0121b93f ^ 0x43c14b22 ^ 0x62564c48 ^ 0xadfaa72e ^
     *        0xf74928b5 ^ 0x79cc9351 ^ 0xe92e5c34 ^ 0x3fbd4216 ^
     *        0x609ff1bd ^ 0xbaf8f441 ^ 0xc828371e ^ 0x439f5ac2 ^
     *        0xa1774da0 ^ 0xca656e5a ^ 0x44a09e65 ^ 0x9e35bf13 == 0x350dd611
     */
    bytes4 private constant _INTERFACE_ID_ERC1417 = 0x350dd611;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('pollType()')) == 0x237637a8
     *
     *     => 0x06fdde03 ^ 0x237637a8 == 0x258be9ab
     */
    bytes4 private constant _INTERFACE_ID_ERC1417_METADATA = 0x258be9ab;

    /**
     * @dev Emitted when `voter` is granted.
     */
    event VoterGranted(address indexed voter, uint256 weight);

    /**
     * @dev Initializes the contract by setting a `name` and a `type`,
     *  as well as `proposalNames`.
     */
    constructor (string memory name, string memory pollType, bytes32[] memory proposalNames) public {
        _name = name;
        _type = pollType;

        for (uint256 i = 0; i < proposalNames.length; i++) {
            _proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0,
                voteWeight: 0
            }));
        }

        // register the supported interfaces to conform to ERC1417 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1417);
        _registerInterface(_INTERFACE_ID_ERC1417_METADATA);
    }

    /**
     * @dev See {IERC1417Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC1417Metadata-pollType}.
     */
    function pollType() public view override returns (string memory) {
        return _type;
    }

    /**
     * @dev Returns `voter` weight.
     */
    function getWeight(address voter) public view returns (uint256) {
        return _voters[voter].weight;
    }

    /**
     * @dev See {IERC1417-getProposals}.
     */
    function getProposals() public view override returns (bytes32[] memory) {
        bytes32[] memory proposalNames = new bytes32[](_proposals.length);

        for (uint256 i = 0; i < _proposals.length; i++) {
            proposalNames[i] = _proposals[i].name;
        }

        return proposalNames;
    }

    /**
     * @dev See {IERC1417-canVote}.
     */
    function canVote(address to) public view override returns (bool) {
        require(to != address(0), "ERC1417: the address is the zero address");
        return _voters[to].weight != 0;
    }

    /**
     * @dev See {IERC1417-allVote}.
     */
    function allVote() public view override returns (bool) {
        uint256 totalVotes = 0;

        for (uint256 i = 0; i < _proposals.length; i++) {
            totalVotes = totalVotes.add(_proposals[i].voteCount);
        }

        return ((totalVotes > 0) && (totalVotes == _pollVoters.length()));
    }

    /**
     * @dev Checks if user in voters
     */
    function isVoter(address voter) public view returns (bool) {
        return _pollVoters.contains(voter);
    }

    /**
     * @dev Gets voters
     */
    function getVoters() public view returns (address[] memory) {
        address[] memory voters = new address[](_pollVoters.length());

        for (uint256 i = 0; i < _pollVoters.length(); i++) {
            voters[i] = _pollVoters.at(i);
        }

        return voters;
    }

    /**
     * @dev See {IERC1417-getVoteTally}.
     */
    function getVoteTally(uint256 proposalId) public view override returns (uint256) {
        return _proposals[proposalId].voteWeight;
    }

    /**
     * @dev See {IERC1417-getVoterCount}.
     */
    function getVoterCount(uint256 proposalId) public view override returns (uint256) {
        return _proposals[proposalId].voteCount;
    }

    /**
     * @notice Not implement at this time, but might do it in the future.
     * @dev See {IERC1417-calculateVoteWeight}.
     */
    function calculateVoteWeight(address /* to */) public view override returns (uint256) {
        // solium-disable-previous-line no-empty-blocks
    }

    /**
     * @dev See {IERC1417-winningProposal}.
     */
    function winningProposal() public view override returns (uint256) {
        uint256 winningProposalIndex = 0;
        uint256 winningVoteCount = 0;

        for (uint256 i = 0; i < _proposals.length; i++) {
            if (_proposals[i].voteWeight > winningVoteCount) {
                winningVoteCount = _proposals[i].voteWeight;
                winningProposalIndex = i;
            }
        }

        return winningProposalIndex;
    }

    /**
     * @dev Returns the leading proposal name at the current time
     */
    function winningName() public view returns (bytes32) {
        return _proposals[winningProposal()].name;
    }

    /**
     * @notice Not implement at this time, but might do it in the future.
     * @dev See {IERC1417-getVoterBaseLogic}.
     */
    function getVoterBaseLogic() public view override returns (string memory) {
        // solium-disable-previous-line no-empty-blocks
    }

    /**
     * @notice Not implement at this time, but might do it in the future.
     * @dev See {IERC1417-getStartTime}.
     */
    function getStartTime() public view override returns (uint256) {
        // solium-disable-previous-line no-empty-blocks
    }

    /**
     * @notice Not implement at this time, but might do it in the future.
     * @dev See {IERC1417-getEndTime}.
     */
    function getEndTime() public view override returns (uint256) {
        // solium-disable-previous-line no-empty-blocks
    }

    /**
     * @notice Not implement at this time, but might do it in the future.
     * @dev See {IERC1417-getProtocolAddresses}.
     */
    function getProtocolAddresses() public view override returns (address[] memory) {
        // solium-disable-previous-line no-empty-blocks
    }

    /**
     * @dev See {IERC1417-getVoteTallies}.
     */
    function getVoteTallies() public view override returns (uint256[] memory) {
        uint256[] memory proposalWeights = new uint256[](_proposals.length);

        for (uint256 i = 0; i < _proposals.length; i++) {
            proposalWeights[i] = _proposals[i].voteWeight;
        }

        return proposalWeights;
    }

    /**
     * @dev See {IERC1417-getVoterCounts}.
     */
    function getVoterCounts() public view override returns (uint256[] memory) {
        uint256[] memory proposalCounts = new uint256[](_proposals.length);

        for (uint256 i = 0; i < _proposals.length; i++) {
            proposalCounts[i] = _proposals[i].voteCount;
        }

        return proposalCounts;
    }

    /**
     * @notice Not implement at this time, but might do it in the future.
     * @dev See {IERC1417-getVoterBaseDenominator}.
     */
    function getVoterBaseDenominator() public view override returns (uint256) {
        // solium-disable-previous-line no-empty-blocks
    }

    /**
     * @dev See {IERC1417-vote}.
     */
    function vote(uint256 proposalId) public virtual override {
        _beforeVote(proposalId);

        Voter storage sender = _voters[_msgSender()];
        uint256 voteWeight = getWeight(_msgSender());

        if (canVote(_msgSender()) && !sender.voted && proposalId < _proposals.length) {
            sender.voted = true;
            sender.vote = proposalId;

            _proposals[proposalId].voteWeight = _proposals[proposalId].voteWeight.add(voteWeight);
            _proposals[proposalId].voteCount = _proposals[proposalId].voteCount.add(1);

            emit CastVote(_msgSender(), proposalId, voteWeight);
        } else {
            emit TriedToVote(_msgSender(), proposalId, voteWeight);
        }
    }

    /**
     * @dev See {IERC1417-revokeVote}.
     */
    function revokeVote() public virtual override {
        Voter storage sender = _voters[_msgSender()];

        require(sender.voted, "ERC1417: voter has not yet voted.");

        uint256 proposalId = sender.vote;
        uint256 voteWeight = sender.weight;

        sender.voted = false;
        _proposals[sender.vote].voteWeight = _proposals[sender.vote].voteWeight.sub(sender.weight);
        _proposals[sender.vote].voteCount = _proposals[sender.vote].voteCount.sub(1);
        sender.vote = 0;
        sender.weight = 0;

        emit RevokedVote(_msgSender(), proposalId, voteWeight);
    }

    /**
     * @dev Give `voter` the right to cast on this ballot.
     *
     * Requirements:
     *
     * - `voter` cannot be the zero address.
     * - `voter` cannot already voted.
     * - `voter` cannot be granted right.
     *
     * Emits a {VoterGranted} event.
     */
    function _giveRightToVote(address voter, uint256 weight) internal virtual {
        require(voter != address(0), "ERC1417: voter address is the zero address");
        require(!_voters[voter].voted, "ERC1417: voter already voted.");
        require(_voters[voter].weight == 0, "ERC1417: voter has been already granted right to vote.");

        _pollVoters.add(voter);
        _voters[voter].weight = weight;

        emit VoterGranted(voter, weight);
    }

    /**
     * @dev Hook that is called before any vote cast.
     */
    function _beforeVote(uint256 /* proposalId */) internal virtual {
        // solium-disable-previous-line no-empty-blocks
    }
}
