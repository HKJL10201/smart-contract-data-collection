// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

// user can register base on state and  country
// create Applicant  only owner
//  set vote day
//  set accredicted vote location
//  user can watch vote as e edy go
// https://medium.com/blockcentric/ethereum-dapp-portfolio-ideas-21e1aac6dc52
//https://www.ethhole.com/challenge


enum Post{
    President,
    Senator,
    Governor,
    Assembly,
    Respresentative
}

struct Official{
     string name;
    uint lgaCode;
    address officialAddr;
    bool isActive;
}

struct VoteZone{
    string lga;
    string state;
    uint stateCode;
    uint lgaCode;
}

struct Candidate{
    string name;
    string nin;
    uint lgaCode;
    uint year;
    Post position;
    bool active;
}

struct Voter{
   string name;
    string nin;
    uint lgaCode;  
    bool canVote;
    // byte uniqueVotePin;    
}


interface IOfficial{

    function accredictedNewOfficial(address officialAddress, string calldata officialName, uint lgaCode) external;
    
    function suspendOfficial(address officialAddress) external;

    function removeOfficial(address officialAddress) external;

    function addCandidate(string calldata name, uint nin, Post position, uint lgaCode, uint year) external;

    function suspendCandidate(uint nin) external;

    function removeCandidate(uint nin) external;

    function registerVoter(Voter calldata voter) external;
}

interface IMember{

    function castVote(uint nin) external;

    function whoIFor() external view;

    function watchVote() external view;

}


contract EVote{
    
    address private ownerAddr;
    address[] accredictedOfficialAddr; // hold all official address
    mapping(address=>Official) accredictedOfficialDetails; 
    mapping(uint=>VoteZone) accredictedZone;
    VoteZone[] zones;
    mapping(uint=>string) statesMap;
    string[] states;
    
    modifier isOwnerMod{
        require(ownerAddr != msg.sender,"you can not add official");
        _;
    }

    modifier checkLocalGovtCode(uint code){
        require(accredictedZone[code].lgaCode > 0 , "local government already exist");
        _;
    }

    modifier checkState(uint stateCode){
        require(bytes(statesMap[stateCode]).length < 0, "state does not exist");
        _;
    }
    
    constructor (){
        ownerAddr = msg.sender;
    }

    function getOwner() external view returns (address){
        return ownerAddr;
    }

    function getStates() external view returns(string[] memory) {
        return states;
    }

    function addState(string calldata stateName, uint  stateCode) external isOwnerMod{
        require(bytes(statesMap[stateCode]).length > 0, "state already exist");
        statesMap[stateCode] = stateName;
        states.push(stateName);
    }

    function addLocalGovernment(string calldata lga, uint lgaCode, uint stateCode)  external isOwnerMod checkState(stateCode) checkLocalGovtCode(lgaCode) returns (VoteZone memory _zone){
        string memory _stateName = statesMap[stateCode];
        _zone = VoteZone(lga,_stateName,stateCode,lgaCode);
        accredictedZone[lgaCode] = _zone;
        zones.push(_zone);
    }

    function getLocalGovernment() external view returns (VoteZone[] memory){
       return zones; 
    }

    function accredictedNewOfficial(address officialAddress, string calldata officialName, uint lgaCode) external isOwnerMod{
        require(accredictedZone[lgaCode].lgaCode == 0 , "local government does not exist");
       
        accredictedOfficialAddr.push(officialAddress);
        accredictedOfficialDetails[officialAddress] = Official({
         name: officialName, lgaCode: lgaCode,
        officialAddr: officialAddress,
        isActive: true});
        //check for the code that match the selec
    }


}