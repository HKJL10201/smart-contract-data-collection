// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ElectionRegion.sol";

contract Election {

    /* The owner of this contract and who has special permissions over it */
    address private owner;

    /* Key which will be used to decrypt votes after an election ends */
    string private encryptKey;

    /* Key which will be used to decrypt votes after an election ends */
    string private decryptKey;

    /* The start and end date of the election specified by a Unix Timestamp */
    uint256 private startDateTimestamp;
    uint256 private endDateTimestamp;

    /* The parties that participate in the elections */
    struct Party {
        uint id;
        string name;
        string[] list;
    }
    mapping (uint256 => Party) private parties; // Relation between party ID and party struct
    uint256[] private partiesID; // List of all registered parties ID

    /* The regions that participate on the election */
    mapping (uint => ElectionRegion) private regions; // Relation between region ID and region contract
    uint[] private regionsID; // List of all registered regions ID

    // These following events are used for the testing program
    event PartyIdEvent(uint256 partyID);
    event RegionIdEvent(uint regionID);
    event RegionAddressEvent(address regionAddress);

    /* Restricts functions calls to the owner address */
    modifier onlyOwner {
        require(msg.sender == owner, "Operation restricted to owner");
        _;
    }

    /* Checks if the block timestamp is previous than the election start timestamp */
    modifier onlyBeforeElection {
        require(block.timestamp < startDateTimestamp, "Operation only allowed before elections have started");
        _;
    }

    /* Checks if the block timestamp is between the election start timestamp and the election end timestamp */
    modifier electionOnCourse {
        require(block.timestamp >= startDateTimestamp && block.timestamp < endDateTimestamp, "Operation only allowed when the election is on course");
        _;
    }

    /* Checks if the block timestamp is later or equal than the election end timestamp */
    modifier onlyAfterElection {
        require(block.timestamp >= endDateTimestamp, "Operation only allowed after elections have finished");
        _;
    }

    /* Checks whether the region ID exists */
    modifier regionExists(uint regionID) {
        require(regions[regionID].getID() != 0, "This region ID does not exist");
        _;
    }

    /* Checks whether the party ID exists */
    modifier partyExists(uint256 partyID) {
        require(parties[partyID].id != 0, "This party ID does not exist");
        _;
    }

    constructor(string memory key, uint256 startTimestamp, uint256 endTimestamp) {
        owner = msg.sender;
        regionsID = new uint[](0);
        partiesID = new uint256[](0);
        encryptKey = key;
        startDateTimestamp = startTimestamp;
        endDateTimestamp = endTimestamp;
    }

    /* Sets the decrypt key so votes can be decrypted */
    function setDecryptKey(string memory key) onlyOwner onlyAfterElection external {
        decryptKey = key;
    }

    /* Returns the start date timestamp */
    function getStartTimestamp() external view returns(uint) {
        return startDateTimestamp;
    }

    /* Returns the end date timestamp */
    function getEndTimestamp() external view returns(uint) {
        return endDateTimestamp;
    }

    /* Adds a new party to be voted in the elections. Each party has a name and a candidate list. Returns the ID of the party created */
    function addParty(uint256 partyID, string memory partyName, string[] memory candidateList) onlyOwner onlyBeforeElection external returns(uint) {
        parties[partyID] = Party(partyID, partyName, candidateList);
        partiesID.push(partyID);
        emit PartyIdEvent(partyID);
        return partyID;
    }

    /* Adds a new region. Each region has a name . Returns the ID of the region created */
    function addRegion(string memory regionName) onlyOwner onlyBeforeElection external returns(uint) {
        uint regionID = regionsID.length + 1;
        regions[regionID] = new ElectionRegion(regionID, regionName);
        regionsID.push(regionID);
        emit RegionIdEvent(regionID);
        return regionID++;
    }

    /* Returns the party of the given ID */
    function getPartyById(uint256 partyID) external view returns(Party memory) {
        return parties[partyID];
    }

    /* Returns the region name of the given ID */
    function getRegionById(uint regionID) external returns(address) {
        address addr = address(regions[regionID]);
        emit RegionAddressEvent(addr);
        return addr;
    }

    /* Returns the list of IDs of all parties */
    function getPartiesIDList() external view returns(uint[] memory) {
        return partiesID;
    }

    /* Returns the list of IDs of all parties  */
    function getRegionsIDList() external view returns(uint[] memory) {
        return regionsID;
    }

    /* Adds a new manager to the list of managers of the region specified */
    function addManagerListToRegion(uint regionID, address[] memory managers) onlyOwner onlyBeforeElection external {
        regions[regionID].addManagerList(managers);
    }

    /* Registers a new citizen ID into the region census */
    function registerCitizenList(uint regionID, string[] memory citizensIDList) onlyOwner onlyBeforeElection external {
        regions[regionID].registerCitizenList(citizensIDList);
    }

    /* Marks in the census of the given region if a citizen has obtained his/her vote */
    function citizenObtainedVote(uint regionID, string memory citizenID) electionOnCourse regionExists(regionID) external {
        regions[regionID].citizenObtainedVote(msg.sender, citizenID);
    }

    /* Authorises a list of voters in the given region */
    function authoriseVoterList(uint regionID, address[] memory voterList) onlyOwner onlyBeforeElection regionExists(regionID) external {
        regions[regionID].authoriseVoterList(voterList);
    }

    /* Allows voters to cast their vote into the given region */
    function castVote(uint regionID, string memory vote) electionOnCourse regionExists(regionID) external {
        regions[regionID].castVote(msg.sender, vote);
    }

    /* Returns all votes from a given region */
    function getAllVotesFromRegion(uint regionID) onlyAfterElection regionExists(regionID) view external returns(string[] memory) {
        return regions[regionID].getAllVotes();
    }

    /* Returns the vote cast by voterAddress */
    function getVote(uint regionID, address voterAddress) onlyAfterElection regionExists(regionID) view external returns(string memory) {
        return regions[regionID].getVoteFrom(voterAddress);
    }
}