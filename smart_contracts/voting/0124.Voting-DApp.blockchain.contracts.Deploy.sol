pragma solidity ^0.8.13;

contract Deploy {

    string public voteData;
    string public id;
    string public location;
    uint256 public timestamp;

    constructor(string memory _voteData, string memory _id, string memory _location, uint256 _timestamp) {
        voteData = _voteData;
        id = _id;
        location = _location;
        timestamp = _timestamp;
    }

    function getVoteData() public view returns(string memory) {
        return voteData;
    }

    function getId() public view returns(string memory) {
        return id;
    }

    function getLocation() public view returns(string memory) {
        return location;
    }

    function getTimeStamp() public view returns(uint256) {
        return timestamp;
    }
    
    function getAllData() public view returns(string memory, string memory, string memory, uint256) {
        return (voteData, id, location, timestamp);
    }

}
