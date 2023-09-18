pragma solidity >=0.8.0 <0.9.0;

import "./AnonymousElection.sol";

contract AnonymousElectionCreator {
    // who is the owner of this election creator
    address private owner;
    
    mapping(string => address) private electionsMapping; // maps names to election address
    string[] private electionsList; // list of names of elections
    
    constructor() {
        owner = msg.sender;
        electionsList = new string[](0);
    }
    
    function createElection(string memory _electionName, string[] memory _candidates, address[] memory _voters, bytes memory _p, bytes memory _g) public returns(address) {
        // make sure that the _electionName is unique
        require(electionsMapping[_electionName] == address(0), "Election name not unique. An election already exists with that name");
        require(_candidates.length > 1 && _voters.length > 0, "candidate list and voter list both need to have non-zero length, >1 candidate");
        
        // require none of the candidates are the empty string.
        for (uint256 i = 0; i < _candidates.length; i++) {
            require(bytes(_candidates[i]).length != 0, "candidate cannot be empty string");
        }
        
        // create election
        AnonymousElection election = new AnonymousElection(_candidates, _voters, _p, _g, msg.sender, _electionName);
        
        // create mapping between _electionName and election address
        electionsMapping[_electionName] = address(election);
        
        // add name to electionsList
        electionsList.push(_electionName);
        
        // return the address of the election created
        return address(election);
    }
    
    // return address of an election given the election's name
    function getElectionAddress(string memory _electionName) public view returns(address) {
        // ensure that _electionName is a valid election
        require(electionsMapping[_electionName] != address(0));
        
        // return the address of requested election
        return electionsMapping[_electionName];
    }
    
    // return list of all election names created with this election creator
    function getAllElections() public view returns (string[] memory){
        return electionsList;
    }
}