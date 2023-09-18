// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/ISector.sol";
import "./Tender.sol";
import "./Governance.sol";

contract Sector is ISector {

    uint256 public numberOfSectors;

    mapping(uint256 => Sector) public sectors;

    Governance public _governance;

    // constructor() {

    // }

    function createSector(string memory _name) public onlySuperAdmin(){

        Sector memory _sector = sectors[numberOfSectors];

       _sector.sectorID = numberOfSectors;
       _sector.numberOfTenders = 0;
       _sector.currentFunds = 0;
       _sector.budget = 0;
       _sector.budgetReached = false;
       _sector.sectorName = _name;

        numberOfSectors++;
    }

    function viewAllSetors() public view returns (ISector.Sector[] memory) {
        ISector.Sector[] memory tempSectors = new ISector.Sector[](numberOfSectors);

        for (uint256 i = 0; i < numberOfSectors; i++) {
            tempSectors[i] = sectors[i];
        }

        return tempSectors;
    }

    function getSectorName(uint256 _sectorID) public view returns (string memory){
        return sectors[_sectorID].sectorName;
    }

    //----------------------------------------------------------------------------------------------------------------------
    //-------------------------------------        GETTER FUNCTION        --------------------------------
    //----------------------------------------------------------------------------------------------------------------------

    function getSector(uint256 _sectorID) public view returns (Sector memory) {
        return sectors[_sectorID];
    }

    //----------------------------------------------------------------------------------------------------------------------
    //-------------------------------------        MODIFIER       --------------------------------
    //----------------------------------------------------------------------------------------------------------------------

    modifier onlySuperAdmin() {
        require(msg.sender == _governance.superAdmin(), "ONLY SUPER ADMIN");
        _;
    }
}