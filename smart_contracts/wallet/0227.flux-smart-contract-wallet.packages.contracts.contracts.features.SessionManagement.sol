// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

contract SessionManagement {
    struct Session {
        uint256 blockNumber;
        address target;
        bool active;
    }
    mapping(address => Session) public SessionMap;

    function _createSession(uint256 blockNumber, address target, address sessionAddress) internal {
        SessionMap[sessionAddress] = Session({
            blockNumber: blockNumber,
            target: target,
            active: true
        });
    }

    function _deactivateSession(address sessionAddress) internal {
        SessionMap[sessionAddress].active = false;
    }

    function _canCall(address account, address target) internal view returns(bool) {
        return SessionMap[account].target == target && SessionMap[account].active && block.number <= SessionMap[account].blockNumber;
    }
}
