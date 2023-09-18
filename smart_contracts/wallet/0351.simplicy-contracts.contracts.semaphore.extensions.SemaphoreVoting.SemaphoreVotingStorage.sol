// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


library SemaphoreVotingStorage {
    enum PollState {
        Created,
        Ongoing,
        Ended
    }

    struct Poll {
        address coordinator;
        PollState state;
    }

    struct Layout {
        mapping(uint256 => Poll) polls;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.SemaphoreVoting");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function _setPoolCoordinator(Layout storage s, uint256 poolId, address newCoordinator) internal {
        s.polls[poolId].coordinator = newCoordinator;
    }

    function _setPoolState(Layout storage s, uint256 poolId, PollState newState) internal {
        s.polls[poolId].state = newState;
    }
}
