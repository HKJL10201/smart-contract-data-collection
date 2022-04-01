pragma solidity ^0.7.0;
pragma abicoder v2;


contract VoteDappStorage {
    
    address admin;
    
    mapping(address => bool) public pollTypeExists; //types of polls and their addresses, such as quadratic contract and regular voting contract
    
    mapping(string => bool) public pollNameExists; //storage of Polls and their settings
    
    
    // allows admin to set voting price, on deployment of contract
    constructor() {
        admin = msg.sender; //sets deployer to admin
    }
    
    function addPollType(address[] memory pollAddr) external {
        require(msg.sender == admin, "You are not allowed to do this.");
        
        for(uint256 i=0; i<pollAddr.length; i++) {
            pollTypeExists[pollAddr[i]] = true;
        }
        
    }
    
    function removePollType(address[] memory pollAddr) external {
        require(msg.sender == admin, "You are not allowed to do this.");
        
        for(uint256 i=0; i<pollAddr.length; i++) {
            pollTypeExists[pollAddr[i]] = false;
        }
    }
    
    function addName(string memory pollName) external returns (bool) {
        require(pollTypeExists[msg.sender], "Not valid poll type.");
        
        require(!pollNameExists[pollName], "Name already taken.");
        
        pollNameExists[pollName] = true;
        
        return true;
    }
    
    
    
    
}
