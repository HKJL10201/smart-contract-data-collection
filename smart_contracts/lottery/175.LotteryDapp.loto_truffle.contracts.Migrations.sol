//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract Migrations {
    address public owner = 0x60b2ECb7c8Ed53Bb4b4338860c1CcfCAa5Ff1218;
    uint256 public last_completed_migration;

    modifier restricted() {
        require(
            msg.sender == owner,
            "This function is restricted to contracr owner"
        );
        _;
    }

    function setCompleted(uint256 completed) public restricted {
        last_completed_migration = completed;
    }

    function upgrade(address new_address) public restricted {
        Migrations upgraded = Migrations(new_address);
        upgraded.setCompleted(last_completed_migration);
    }
}
