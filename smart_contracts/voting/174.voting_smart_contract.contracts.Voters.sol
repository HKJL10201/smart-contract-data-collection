pragma solidity ^0.5.16;

import "./DataStructure.sol";

contract Voters is DataStructure {

    /**
     * Voter list length
     */
    uint private VotersLen;

    event voterListAdded(address voter);
    event voterListRemoved(address voter);

    constructor()
    public
    {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        require (
            msg.sender == owner,
            "Must be owner."
        );
    }

    /**
     * @dev Function to add voter
     * @param name is the voter's name
     * @param id is the voter's id
     * @param addr is the voter's address
     */
    function addToVoter(string memory name, string memory id, address addr)
    public
    onlyOwner
    {
        require(addr != address(0), "Error address zero");
        regVoters[addr].name = name;
        regVoters[addr].id = id;
        regVoters[addr].active = true;
        VotersLen++;

        votersList.push(addr);
        emit voterListAdded(addr);
    }

    /**
     * @dev Function to remove voter
     * @param addr is the voter address
     */
    function removeFromVoter(address addr)
    public
    onlyOwner
    {
        require(addr != address(0), "Error address zero");
        require(isVoterListed(addr) == true, "Voter is not listed");
        regVoters[addr].active = false;
        VotersLen++;
        emit voterListRemoved(addr);
    }

    /**
     * @dev Function to get voter by id
     * @param id is the voter name
     */
    function getVoterByID(string memory id)
    public
    view
    returns (string memory, string memory, address, bool)
    {
        require(votersList.length > 0, "None in the list");
        bytes32 tempid = keccak256(abi.encodePacked(id));
        for(uint i=0; i<votersList.length; i++) {
            if(keccak256(abi.encodePacked(regVoters[votersList[i]].id)) == tempid) {
                return (regVoters[votersList[i]].name, 
                        regVoters[votersList[i]].id, 
                        votersList[i],
                        regVoters[votersList[i]].active);
            }
        }
    }

    /**
     * @dev Function to get voter by address
     * @param addr is the voter name
     */
    function getVoterByAddress(address addr)
    public
    view
    returns (string memory, string memory, address, bool)
    {
        return (regVoters[addr].name, 
                regVoters[addr].id, 
                addr,
                regVoters[addr].active);
    }

    /**
     * @dev Function to get all voters
     * @return List of voters
     */
    function getAllVoters()
    public
    view
    returns (address[] memory)
    {
        return votersList;
    }

    /**
     * @dev Function to check if voter existed
     * @param addr is the voter address
     * @return exist or not exist
     */
    function isVoterListed(address addr)
    public
    view
    returns (bool)
    {
        require(addr != address(0), "Error address zero");
        if(VotersLen == 0) {
            return false;
        }
        return regVoters[addr].active;
    }
}

