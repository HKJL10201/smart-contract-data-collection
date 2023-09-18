pragma solidity 0.7.5;
pragma abicoder v2;

import './Admin.sol';

contract VoterPanel is Admin{
    
    struct VoterHistory{
        uint pollId;
        int votes;
    }
    struct Voter{
        uint credits;
        VoterHistory [] history;
    }
    
    mapping(address => Voter)voterLog;
    mapping(address => mapping(uint => bool))checkStatus; // address => pollId => T/F
    
    function voterDetails(address _add) public view returns(Voter memory){
        return voterLog[_add];
    }
}
