// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ISector {

    struct Sector {
        uint256 sectorID;
        uint256 numberOfTenders;
        uint256 currentFunds;
        uint256 budget;
        string sectorName;
        bool budgetReached;
        address sectorAdmin;
    }

    function createSector(string calldata _name) external;

    function getSector(uint256 _sectorID) external view returns (Sector memory);
}