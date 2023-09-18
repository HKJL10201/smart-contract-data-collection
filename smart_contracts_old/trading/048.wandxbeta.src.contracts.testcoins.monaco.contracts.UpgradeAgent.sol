pragma solidity ^0.4.8;
contract UpgradeAgent {
    uint public originalSupply; 
    function isUpgradeAgent() public constant returns (bool) {
        return true;
    }
    function upgradeFrom(address _from, uint256 _value) public;
}