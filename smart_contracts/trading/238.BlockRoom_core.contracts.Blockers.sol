// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./interfaces/IBlockFeed.sol";
import "./helpers/zeroAddressPreventer.sol";

/**
 * @title Blockers
 * @author javadyakuza
 * @notice this contract is used to represent the inviduals as the blockers(users) of the BlockRoom
 */
contract Blockers is ZAP {
    /// @dev emited when a new Blocker is added to the BlockRoom
    event NewBlocker(uint64 _nationalId, address indexed _blocker);

    mapping(address => uint64) private nationalIdOf;
    mapping(address => bool) public isBlocker;

    IBlockFeed public immutable BlockFeed;

    constructor(
        IBlockFeed _tempIBlockFeed
    ) nonZeroAddress(address(_tempIBlockFeed)) {
        BlockFeed = _tempIBlockFeed;
    }

    modifier onlyOnce() {
        // every address can be added only once
        require(!isBlocker[msg.sender], "address is already a Blocker !!");
        _;
        isBlocker[msg.sender] = true;
    }

    function addBlocker(uint64 _nationalId) public onlyOnce {
        require(
            BlockFeed.getBlockerAddress(_nationalId) == msg.sender,
            "user not athenticated !!"
        );
        nationalIdOf[msg.sender] = _nationalId;
        emit NewBlocker(_nationalId, msg.sender);
    }

    function _nationalIdOf(
        address _blocker
    ) external view returns (uint64 _nationalId) {
        return nationalIdOf[_blocker];
    }

    function _isBlocker(
        address _blocker
    ) external view returns (bool _IsBlocker) {
        return isBlocker[_blocker];
    }
}
