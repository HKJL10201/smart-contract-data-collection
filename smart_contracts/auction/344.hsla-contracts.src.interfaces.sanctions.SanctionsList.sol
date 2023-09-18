pragma solidity 0.8.13;

interface SanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}