//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./functions.sol";

contract Voting is Functions{

    //setting the owner
    address public owner;
    constructor() {
        owner = msg.sender;
    }

    //relation between the name of the candidate and their personal data hash
    mapping (string => bytes32) private idCandidate;

    //relation between the candidate name and the number of votes
    mapping(string=>uint) public candidateVotes;

    //list to store the candidates names
    string [] private candidates;

    //list of identity hash of voters
    mapping(address => bool) private voters;

    //counting votes
    uint countingVotes;

    //addCandidate is a function to create a new candidate
    function addCandidate(string memory _name, uint _age, string memory _dni) public {
        bytes32 candidateHash = keccak256(abi.encodePacked(_name, _age, _dni));
        idCandidate[_name] = candidateHash;
        candidates.push(_name);
    }
    //view the list of candidates
    function viewCandidates() public view returns(string [] memory){
        return candidates;
    }

    //vote for one candidate
    function voteCandidate(string memory _name) public checkVote(_name, msg.sender) {
        voters[msg.sender] = true;
        candidateVotes[_name]++;
        countingVotes++;
    }
    //modifier used for checking a vote
    modifier checkVote(string memory _name, address _sender){
        require(idCandidate[_name] != 0, "the name received is not a valid one.");
        require(voters[_sender] == false, "you've already voted");
        _;
    }
    
    //view the results of the votation
    function viewResults() public view returns(string memory){
        string memory result = "";
        for (uint256 i = 0; i < candidates.length; i++) {
            uint numberOfVotes = candidateVotes[candidates[i]];
            result = string(abi.encodePacked(result, "Name: ", candidates[i], ", Number of votes: ",uint2str(numberOfVotes) , "-------"));
        }
        return result;
    }
    //view the winner of the votation
    function winner() public view returns(string memory){
        string memory _winner;
        uint votes;
        string memory result;
        if (candidates.length > 1 && countingVotes > 0) {
        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidateVotes[candidates[i]] > votes) {
                _winner = candidates[i];
                votes = candidateVotes[candidates[i]];
                result = string(abi.encodePacked("the winner is ", _winner, " with ", uint2str(votes), " votes."));
            }else if (candidateVotes[candidates[i]] == votes){
                result = string(abi.encodePacked("there's a draw between ", _winner, " and ", candidates[i], " with ", uint2str(votes) ,"votes"));
            }
        }
        }else{
            result = "not enough candidates or votes";
            return result;
        } 
        bytes memory tempStr = bytes(result);
        if (tempStr.length == 0 ){
            result = "there aren't votes yet";
        }
        return result;
    }

}
