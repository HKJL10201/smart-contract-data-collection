// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/introspection/ERC165Checker.sol";

import "../interfaces/ISmarTrade.sol";
import "../ERC1417/IERC1417.sol";

/**
 * @title SmarTrade Standard basic implementation
 */
contract SmarTrade is Context, ISmarTrade {
    using SafeMath for uint256;
    using Address for address;
    using ERC165Checker for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Counters for Counters.Counter;

    // Trade id tracker
    Counters.Counter private _tradeIdTracker;

    // The set of trade participants
    EnumerableSet.AddressSet private _participants;

    // The poll for next trade
    address private _poll;

    // The next trade proposal
    uint256 private _nextTradeProposal;

    // Trade id
    uint256 private _tradeId;

    // Trade name
    string private _tradeName;

    // Trade type
    string private _tradeType;

    // IPFS hash
    string private _ipfsHash;

    // Base URI
    string private _baseURI;

    // The parent trade
    address private _parentTrade;

    // The child trade
    address private _childTrade;

    /**
     * @dev Initializes the trade contract with `tradeId`, `tradeName`, `tradeType`,
     *  `participants` and `parentTrade`.
     */
    constructor (
        string memory tradeName,
        string memory tradeType,
        address[] memory participants,
        address parentTrade
    )
        public
    {
        _tradeName = tradeName;
        _tradeType = tradeType;
        _parentTrade = parentTrade;

        for (uint256 i = 0; i < participants.length; i++) {
            _participants.add(participants[i]);
        }

        // Trade id tracker
        _tradeId = _tradeIdTracker.current();
        _tradeIdTracker.increment();
    }

    /**
     * @dev See {ISmarTrade-tradeId}.
     */
    function tradeId() public view override returns (uint256) {
        return _tradeId;
    }

    /**
     * @dev See {ISmarTrade-tradeName}.
     */
    function tradeName() public view override returns (string memory) {
        return _tradeName;
    }

    /**
     * @dev See {ISmarTrade-tradeType}.
     */
    function tradeType() public view override returns (string memory) {
        return _tradeType;
    }

    /**
     * @dev See {ISmarTrade-getParticipants}.
     */
    function getParticipants() public view override returns (address[] memory) {
        address[] memory participants = new address[](_participants.length());

        for (uint256 i = 0; i < _participants.length(); i++) {
            participants[i] = _participants.at(i);
        }

        return participants;
    }

    /**
     * @dev Returns the parent trade.
     */
    function getParentTrade() public view returns (address) {
        return _parentTrade;
    }

    /**
     * @dev Returns the child trade.
     */
    function getChildTrade() public view returns (address) {
        return _childTrade;
    }

    /**
     * @dev See {ISmarTrade-getPoll}.
     */
    function getPoll() public view override returns (address) {
        return _poll;
    }

    /**
     * @dev See {ISmarTrade-getIPFSHash}.
     */
    function getIPFSHash() public view override returns (string memory) {
        return _ipfsHash;
    }

    /**
     * @dev Returns the base URI set via {_setBaseURI}.
     */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for IPFS storage.
     */
    function getStorage() public view returns (string memory) {
        // If there is no base URI, return the IPFS hash.
        if (bytes(_baseURI).length == 0) {
            return _ipfsHash;
        }

        return string(abi.encodePacked(_baseURI, _ipfsHash));
    }

    /**
     * @dev See {ISmarTrade-canCreateNextTrade}.
     */
    function canCreateNextTrade() public view override returns (bool) {
        // Can create next trade when poll is not been set
        if (_poll == address(0)) {
            return true;
        }

        bool allVote =  IERC1417(_poll).allVote();
        uint256 winningProposal = IERC1417(_poll).winningProposal();

        if (allVote && (winningProposal == _nextTradeProposal)) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev See {ISmarTrade-setChildTrade}.
     */
    function setChildTrade(address childTrade) public virtual override {
        require(
            childTrade != address(0),
            "SmarTrade: cannot be the zero address"
        );

        require(
            childTrade.isContract(),
            "SmarTrade: must be contract"
        );

        require(
            _childTrade == address(0),
            "SmarTrade: child trade has already been set"
        );

        _childTrade = childTrade;

        emit NextTrade(childTrade);
    }

    /**
     * @dev See {ISmarTrade-createPoll}.
     */
    function createPoll(address poll, uint256 nextTradeProposal)
        public
        virtual
        override
    {
        require(
            poll != address(0),
            "SmarTrade: the poll is the zero address"
        );

        require(
            poll.supportsInterface(bytes4(0x350dd611)),
            "SmarTrade: need to conform to ERC1417"
        );

        require(
            _poll == address(0),
            "SmarTrade: can only create poll once"
        );

        emit PollCreated(poll);

        // Sets the poll
        _poll = poll;
        _nextTradeProposal = nextTradeProposal;
    }

    /**
     * @dev Internal function to set IPFS hash.
     */
    function _setIPFSHash(string memory ipfsHash_) internal virtual {
        _ipfsHash = ipfsHash_;
    }

    /**
     * @dev Internal function to set the base URI for IPFS hash.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }
}
