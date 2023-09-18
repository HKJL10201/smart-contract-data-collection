// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./ERC1417/ERC1417.sol";
import "./ERC1417/ERC1417Pausable.sol";

/**
 * @dev {SmarPoll}
 */
contract SmarPoll is AccessControl, ERC1417Pausable {
    bytes32 public constant SUPER_ROLE = keccak256("SUPER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `SUPER_ROLE` and `PAUSER_ROLE` to the account that deploys
     *  the contract.
     */
    constructor(
        string memory name,
        string memory pollType,
        bytes32[] memory proposalNames,
        address[] memory voters,
        uint256[] memory weights
    )
        public
        ERC1417(name, pollType, proposalNames)
    {
        require(
            voters.length > 0,
            "SmarPoll: voters must be greater than zero"
        );

        require(
            voters.length == weights.length,
            "SmarPoll: voters are not equal to weights"
        );

        _setupRole(SUPER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        // Sets each role admin to super role
        _setRoleAdmin(PAUSER_ROLE, SUPER_ROLE);
        _setRoleAdmin(SUPER_ROLE, SUPER_ROLE);

        for (uint256 i = 0; i < voters.length; i++) {
            _giveRightToVote(voters[i], weights[i]);
        }
    }

    /**
     * @dev See {ERC1417-_giveRightToVote}.
     *
     * Requirements:
     *
     * - Only voter can invite others
     */
    function giveRightToVote(address voter, uint256 weight) public virtual {
        require(
            !paused(),
            "SmarPoll: give right to vote while paused"
        );

        require(
            isVoter(_msgSender()),
            "SmarPoll: only voter can invite others"
        );

        _giveRightToVote(voter, weight);
    }

    /**
     * @dev Pauses all voter casts.
     *
     * See {ERC1417Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - caller must have pauser role (`PAUSER_ROLE`).
     */
    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "SmarPoll: must have pauser role to pause"
        );

        _pause();
    }

    /**
     * @dev Unpauses all voter casts.
     *
     * See {ERC1417Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - caller must have pauser role (`PAUSER_ROLE`).
     */
    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "SmarPoll: must have pauser role to unpause"
        );

        _unpause();
    }
}
