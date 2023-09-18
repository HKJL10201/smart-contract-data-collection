// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract ElectionRegion {

    /* The owner of this contract and who has special permissions over it */
    address private owner;

    /* The region name */
    string private name;

    /* The region ID */
    uint id;

    /*
    Managers addresses can perform some special actions in order to administrate the course of an election, 
    like mark the citizens in the census when they have already obtained their vote so they do not obtain another vote
    */
    mapping(address => bool) private isManager;
    address[] private managerList;

    /*
    Relationship between the citizens real IDs and a struct that indicates:
        1. If they are authorised to participate in the election
        2. If they have already obtained their vote (authorised account address) or not
    */
    struct Citizen {
        bool isRegistered;
        bool voteObtained;
    }
    mapping(string => Citizen) private census;
    string[] private citizensID;

    /* Struct that represents if the voter is authorised, if it has already voted and the vote cast */
    struct Voter {
        bool isAuthorised;
        bool hasVoted;
        string vote;
    }
    /* A mapping relationship between the voters addresses and a struct that represents the voter */
    mapping(address => Voter) private voters;
    address[] private votersList; // And array that stores all voters addresses in this region
    mapping(string => bool) private votes; // Mapping that indicates if a type of vote has already been cast

    /* Restricts function calls to the owner address */
    modifier onlyOwner {
        require(msg.sender == owner, "Operation restricted to owner");
        _;
    }

    /* Checks whether the voter address is authorised in this region */
    modifier voterIsAuthorised(address voterAddress) {
        require(voters[voterAddress].isAuthorised, "Operation restricted to authorised voters in this region");
        _;
    }

    /* Checks if the voter address is not authorised in this region */
    modifier voterIsNotAuthorised(address voterAddress) {
        require(!voters[voterAddress].isAuthorised, "Operation restricted to not authorised voters in this region");
        _;
    }

    /* Restricts function calls to authorised voters in this region */
    modifier voterHasNotVoted(address voterAddress) {
        require(!voters[voterAddress].hasVoted, "Operation restricted to voters who have not cast a vote");
        _;
    }

    modifier voterHasVoted(address voterAddress) {
        require(voters[voterAddress].hasVoted, "Operation restricted to voters who have cast a vote");
        _;
    }

    /* Checks if a citizen ID is authorised to participate in the elections */
    modifier citizenRegistered(string memory citizenID) {
        require(census[citizenID].isRegistered, "Citizen is not registered into the elections");
        _;
    }

    /* Checks if a citizen ID is not authorised to participate in the elections */
    modifier citizenNotRegistered(string memory citizenID) {
        require(!census[citizenID].isRegistered, "Citizen is already registered into the elections");
        _;
    }

    /* Checks if a citizen ID is not authorised to participate in the elections */
    modifier citizenNotObtainedVote(string memory citizenID) {
        require(!census[citizenID].voteObtained, "Citizen has already obtained a vote");
        _;
    }

    /* Restricts some operations to manager addresses */
    modifier onlyManager(address managerAddress) {
        require(isManager[managerAddress], "Operation restricted to managers");
        _;
    }

    modifier voteNotRepeated(string memory vote) {
        require(!votes[vote], "This vote has already been cast; cast another one");
        _;
    }

    constructor(uint regionID, string memory regionName) {
        owner = msg.sender;
        name = regionName;
        id = regionID;
        
        managerList = new address[](0);
        votersList = new address[](0);
        citizensID = new string[](0);
    }

    /* Adds a list of new managers */
    function addManagerList(address[] memory managers) onlyOwner external {
        for(uint i = 0; i < managers.length; i++) {
            require(!isManager[managers[i]], "This address is already manager");
            managerList.push(managers[i]);
            isManager[managers[i]] = true;
        }
    }

    /* Returns the list of managers */
    function getManagers() external view returns(address[] memory) {
        return managerList;
    }

    function accountIsManager(address addr) view external returns(bool) {
        return isManager[addr];
    } 

    /* Registers a new citizen ID into the election census */
    function registerCitizen(string memory citizenID) citizenNotRegistered(citizenID) internal {
        citizensID.push(citizenID);
        census[citizenID].isRegistered = true;
    }

    /* Registers a new citizen ID list into the election census */
    function registerCitizenList(string[] memory citizensIDList) onlyOwner external {
        for(uint i = 0; i < citizensIDList.length; i++) {
            registerCitizen(citizensIDList[i]);
        }
    }

    /* Marks in the census if a citizen has obtained his/her vote */
    function citizenObtainedVote(address managerAddress, string memory citizenID) onlyOwner onlyManager(managerAddress) citizenRegistered(citizenID) citizenNotObtainedVote(citizenID) external {
        census[citizenID].voteObtained = true;
    }

    /* Returns whether citizens have obtained their vote */
    function citizenHasObtainedVote(string memory citizenID) citizenRegistered(citizenID) view external returns(bool) {
        return census[citizenID].voteObtained;
    }

    /* Returns if a citizen is registered into the election census */
    function citizenIsRegistered(string memory citizenID) view external returns(bool) {
        return census[citizenID].isRegistered;
    }

    /* Returns the citizens registered in this regions (the census) */
    function getCensus() view external returns(string[] memory) {
        return citizensID;
    }

    /* Authorises a new voter address into this region */
    function authoriseVoterList(address[] memory votersAddressesList) onlyOwner external {
        for(uint i = 0; i < votersAddressesList.length; i++) {
            require(!voters[votersAddressesList[i]].isAuthorised, "This voter is already authorised in this region");
            voters[votersAddressesList[i]].isAuthorised = true;
            votersList.push(votersAddressesList[i]);
        }
    }

    /* Returns whether an address is authorised to vote in this region */
    function isAuthorised(address voterAddress) view external returns(bool) {
        return voters[voterAddress].isAuthorised;
    }

    /* Returns whether a voter address has already voted */
    function hasVoted(address voterAddress) voterIsAuthorised(voterAddress) view external returns(bool) {
        return voters[voterAddress].hasVoted;
    }

    /* Returns the vote cast by the voter address */
    function getVoteFrom(address voterAddress) onlyOwner voterIsAuthorised(voterAddress)  voterHasVoted(voterAddress) view external returns(string memory) {
        return voters[voterAddress].vote;
    }

    /* Returns all cast votes */
    function getAllVotes() onlyOwner view external returns(string[] memory) {
        string[] memory votes_res = new string[](votersList.length);
        for(uint i = 0; i < votersList.length; i++) {
            if(voters[votersList[i]].hasVoted) votes_res[i] = voters[votersList[i]].vote;
        }
        return votes_res;
    }

    /* Returns the list of authorised voters in this region */
    function getAuthorisedVoters() view external returns(address[] memory) {
        return votersList;
    }

    /* Allows a voter to cast a vote in this region if it is authorised and has not already voted */
    function castVote(address voterAddress, string memory vote) onlyOwner voterIsAuthorised(voterAddress) voterHasNotVoted(voterAddress) voteNotRepeated(vote) external {
        voters[voterAddress].hasVoted = true;
        voters[voterAddress].vote = vote;
        votes[vote] = true;
    }

    /* Returns the name of this region */
    function getName() external view returns(string memory) {
        return name;
    }

    /* Returns the ID of this region */
    function getID() external view returns(uint) {
        return id;
    }
}