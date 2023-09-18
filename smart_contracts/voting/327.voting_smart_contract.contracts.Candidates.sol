pragma solidity ^0.5.16;

import "./DataStructure.sol";

contract Candidates is DataStructure {

    /**
     * Candidate list length
     */
    uint private candidatesLen;

    event candidateListAdded(address candidate);
    event candidateListRemoved(address candidate);

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
     * @dev Function to add candidate
     * @param name is the candidate's name
     * @param id is the candidate's id
     * @param group is the candidate's group
     * @param addr is the candidate address
     */
    function addToCandidate(string memory name, string memory id, string memory group, address addr)
    public
    onlyOwner
    {
        require(addr != address(0), "Error address zero");
        regCandidates[addr].name = name;
        regCandidates[addr].id = id;
        regCandidates[addr].group = group;
        regCandidates[addr].active = true;
        candidatesLen++;

        candidatesList.push(addr);
        emit candidateListAdded(addr);
    }

    /**
     * @dev Function to remove candidate
     * @param addr is the candidate address
     */
    function removeFromCandidate(address addr)
    public
    onlyOwner
    {
        require(addr != address(0), "Error address zero");
        require(isCandidateListed(addr) == true, "Candidate is not listed");
        regCandidates[addr].active = false;
        candidatesLen++;
        emit candidateListRemoved(addr);
    }

        /**
     * @dev Function to get candidate by id
     * @param id is the candidate name
     */
    function getCandidateByID(string memory id)
    public
    view
    returns (string memory, string memory, string memory, address, bool)
    {
        require(candidatesList.length > 0, "None in the list");
        bytes32 tempid = keccak256(abi.encodePacked(id));
        for(uint i=0; i<candidatesList.length; i++) {
            if(keccak256(abi.encodePacked(regCandidates[candidatesList[i]].id)) == tempid) {
                return (regCandidates[candidatesList[i]].name, 
                        regCandidates[candidatesList[i]].id, 
                        regCandidates[candidatesList[i]].group, 
                        candidatesList[i],
                        regCandidates[candidatesList[i]].active);
            }
        }
    }

    /**
     * @dev Function to get candidate by address
     * @param addr is the candidate name
     */
    function getCandidateByAddress(address addr)
    public
    view
    returns (string memory, string memory, string memory, address, bool)
    {
        return (regCandidates[addr].name, 
                regCandidates[addr].id, 
                regCandidates[addr].group,
                addr,
                regCandidates[addr].active);
    }

    /**
     * @dev Function to get all candidate
     * @return List of candidates
     */
    function getAllCandidates()
    public
    view
    returns (address[] memory)
    {
        return candidatesList;
    }

    /**
     * @dev Function to check if candidate existed
     * @param addr is the candidate address
     * @return exist or not exist
     */
    function isCandidateListed(address addr)
    public
    view
    returns (bool)
    {
        require(addr != address(0), "Error address zero");
        if(candidatesLen == 0) {
            return false;
        }
        return regCandidates[addr].active;
    }
}

