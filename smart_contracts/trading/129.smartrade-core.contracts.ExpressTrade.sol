// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "./trade/SmarTrade.sol";

/**
 * @dev {ExpressTrade}
 */
contract ExpressTrade is AccessControl, Pausable, SmarTrade {
    bytes32 public constant SUPER_ROLE = keccak256("SUPER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `SUPER_ROLE` and `PAUSER_ROLE` to the account that deploys
     *  the contract.
     */
    constructor(
        string memory tradeName,
        string memory tradeType,
        address[] memory participants,
        address parentTrade
    )
        public
        SmarTrade(
            tradeName,
            tradeType,
            participants,
            parentTrade
        )
    {
        _setupRole(SUPER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        // Sets each role admin to super role
        _setRoleAdmin(PAUSER_ROLE, SUPER_ROLE);
        _setRoleAdmin(SUPER_ROLE, SUPER_ROLE);
    }

    /**
     * @dev See {SmarTrade-_setIPFSHash}.
     *
     * Requirements:
     *
     * - the caller must have super role (`SUPER_ROLE`).
     */
    function setIPFSHash(string memory ipfsHash_) public virtual {
        require(
            hasRole(SUPER_ROLE, _msgSender()),
            "ExpressTrade: must have super role"
        );

        _setIPFSHash(ipfsHash_);
    }

    /**
     * @dev See {SmarTrade-_setBaseURI}.
     *
     * Requirements:
     *
     * - the caller must have super role (`SUPER_ROLE`).
     */
    function setBaseURI(string memory baseURI_) public virtual {
        require(
            hasRole(SUPER_ROLE, _msgSender()),
            "ExpressTrade: must have super role"
        );

        _setBaseURI(baseURI_);
    }

    /**
     * @dev Sets {SmarTrade-setChildTrade}.
     *
     * Requirements:
     *
     * - the caller must have super role (`SUPER_ROLE`).
     */
    function setChildTrade(address childTrade) public virtual override {
        require(
            hasRole(SUPER_ROLE, _msgSender()),
            "ExpressTrade: must have super role"
        );

        super.setChildTrade(childTrade);
    }

    /**
     * @dev See {SmarTrade-createPoll}.
     *
     * Requirements:
     *
     * - can only call when not paused.
     * - caller must have super role (`SUPER_ROLE`).
     */
    function createPoll(address poll, uint256 nextTradeProposal)
        public
        virtual
        override
    {
        require(
            !paused(),
            "ExpressTrade: create poll while paused"
        );

        require(
            hasRole(SUPER_ROLE, _msgSender()),
            "ExpressTrade: only super role can create poll"
        );

        super.createPoll(poll, nextTradeProposal);
    }

    /**
     * @dev Pauses trade.
     *
     * See {Pausable-_pause}.
     *
     * Requirements:
     *
     * - caller must have pauser role (`PAUSER_ROLE`).
     */
    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ExpressTrade: must have pauser role to pause"
        );

        _pause();
    }

    /**
     * @dev Unpauses trade.
     *
     * See {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - caller must have pauser role (`PAUSER_ROLE`).
     */
    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ExpressTrade: must have pauser role to unpause"
        );

        _unpause();
    }
}
