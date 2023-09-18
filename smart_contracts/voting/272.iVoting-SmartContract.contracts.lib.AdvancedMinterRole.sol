pragma solidity ^0.5.0;

import "./MinterRole.sol";
import "./MasterRole.sol";

contract AdvancedMinterRole is MinterRole, MasterRole{

    function removeMinter(address account) public onlyMaster {
        _removeMinter(account);
    }

    function isAdvancedMinter(address account) public view returns (bool) {
        return isMinter(account);
    }
}