// SPDX-License-Identifier: MIT

import "../openzeppelin-solidity/contracts/ERC1155/ERC1155.sol";

pragma solidity ^0.8.3;

contract TestSyntheticBotToken is ERC1155 {
    constructor() {}

    uint256 public rewardsEndOn;

    function setRewardsEndOn(uint256 _timestamp) external {
        rewardsEndOn = _timestamp;
    }

    function getTokenPrice() external pure returns (uint256) {
        return 5e18;
    }

    function testMint(uint256 _positionID, uint256 _amount) external {
        _mint(msg.sender, _positionID, _amount, "");
    }

    function getPosition(uint256) external view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        return (0, 0, rewardsEndOn, 0, 0, 0);
    }
}