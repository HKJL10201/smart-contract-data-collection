// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ICitizen {

    struct Citizen {
    uint256 citizenID;
    uint256 salary;

    //Stored out of 10_000 for scale
    uint256 taxPercentage;
    uint256 primarySectorID;
    uint256 secondarySectorID;
    uint256 totalTaxPaid;

    //Total taxPaid / 1000
    uint256 totalPriorityPoints;
    address walletAddress;
    string firstName;
    string secondName;
    }

    function selectSectors(uint256 _citizenID, uint256 _primarySectorID, uint256 _secondarySectorID) external;

    function register(Citizen calldata _citizen) external;
    
}