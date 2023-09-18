// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/ICitizen.sol";
import "./Sector.sol";

contract Citizen is ICitizen {

    uint256 public numberOfCitizens;

    mapping(uint256 => Citizen) public citizens;

    Sector public _sectorFacet;

    //Mapping of citizen addresses => id's
    mapping(address => uint256) userAddressesToIDs;

    event SectorsSelected(uint256 _citizenID, uint256 _primarySector, uint256 _secondarySector);
    event CitizenRegistered(uint256 _citizenID, uint256 _numberOfCitizens);

    function selectSectors(uint256 _citizenID, uint256 _primarySectorID, uint256 _secondarySectorID) public {

        require(_primarySectorID != _secondarySectorID, "SECTORS CANNOT BE THE SAME");
        require(_primarySectorID <= _sectorFacet.numberOfSectors(), "INVALID PRIMARY SECTOR ID");
        require(_secondarySectorID <= _sectorFacet.numberOfSectors(), "INVALID SECONDARY SECTOR ID");
        

        citizens[_citizenID].primarySectorID = _primarySectorID;
        citizens[_citizenID].secondarySectorID = _secondarySectorID;

        emit SectorsSelected(_citizenID, citizens[_citizenID].primarySectorID, citizens[_citizenID].secondarySectorID);

    }

    function register(Citizen memory _citizen) public {
        //Check they are a SA citizen through chainlink

        _citizen.citizenID = numberOfCitizens;
        _citizen.taxPercentage = 0;
        _citizen.totalTaxPaid = 0;
        _citizen.totalPriorityPoints = 20;
        _citizen.salary = 0;
        _citizen.walletAddress = msg.sender;

        citizens[numberOfCitizens] = _citizen;
        userAddressesToIDs[msg.sender] = numberOfCitizens;
        numberOfCitizens++;


        emit CitizenRegistered(_citizen.citizenID, numberOfCitizens);

    }

    //----------------------------------------------------------------------------------------------------------------------
    //-------------------------------------        GETTER FUNCTIONS        --------------------------------
    //----------------------------------------------------------------------------------------------------------------------

    function getCitizenPrimaryID(uint256 _citizenID) public view returns (uint256){
        return citizens[_citizenID].primarySectorID;
    }

    function getCitizenSecondaryID(uint256 _citizenID) public view returns (uint256){
        return citizens[_citizenID].secondarySectorID;
    }

    function getCitizen(uint256 _citizenID) public view returns (Citizen memory){
        return citizens[_citizenID];
    }

    function getUserID(address _citizenID) public view returns (uint256){
        return userAddressesToIDs[_citizenID];
    }
    
}