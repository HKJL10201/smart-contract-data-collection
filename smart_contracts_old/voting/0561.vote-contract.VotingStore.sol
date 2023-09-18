// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./DataType.sol";

contract VotingStore is DataType {

    // data
    Candidate[] public candidates;
    mapping(uint256 => uint256) public votingMap;
    mapping(address => uint256) public votingTimeMap;
    uint256 public serialId;

    uint256[] public idList;

    constructor() {
        serialId = 0;
    }

    // fuction
    function setCandidates(Candidate[] memory _candidates) external {
        for(uint256 i = 0; i < _candidates.length; i++) {
            candidates.push(_candidates[i]);
            idList.push(_candidates[i].id);
        }
    }

    function getCandidates() external view returns(Candidate[] memory) {
        return candidates;
    }

    function setSerialId(uint256 _value) external {
        serialId = _value;
    }

    function getSerialId() external view returns(uint256) {
        return serialId;
    }

    function setVotingMap(uint256 _key, uint256 _value) external {
        votingMap[_key] = _value;
    }

    function getCountById(uint256 _id) external view returns(uint256) {
        return votingMap[_id];
    }

    function setVotingTimeMap(address _key, uint256 _value) external {
        votingTimeMap[_key] = _value;
    }

    function getVotingTimeMap(address _key) external view returns(uint256) {
        return votingTimeMap[_key];
    }

    function getIdListLength() external view returns(uint256) {
        return idList.length;
    }
    function getIdList() external view returns(uint256[] memory) {
        return idList;
    }
    
}