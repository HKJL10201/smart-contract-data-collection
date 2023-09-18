// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.4.0 <0.9.0;

contract Vote {

    mapping(string=>string[]) public candidateVote;
    mapping(string => mapping(string => uint)) public voteCount;
    mapping(string=>mapping(address => bool)) public voters;
 
    address public myaddress;

    struct Candidate {
        string name;
        uint votes;
    }

    struct Name{
        string name;
        uint256 votes;
    }


    constructor(){

                
    }

    function createVote(string memory voteName, string[] memory candidateOption) public returns(string memory){

        require(bytes(voteName).length > 0, "you must set a name for your voting.");
        require(candidateOption.length > 0, "Candidate options cannot be empty.");
        require(candidateVote[voteName].length == 0,"the Poll already existed!");
        
        candidateVote[voteName] = candidateOption;

        require(candidateVote[voteName].length > 0, "something is wrong!");

        return "create vote successful!";
        
    }

    function addVote(string memory voteName, string memory candidate, address addr) public returns(string memory){

        require(candidateVote[voteName].length > 0, "Vote does not exist.");
        
        require(!voters[voteName][addr], "Address has already voted!");

        voteCount[voteName][candidate]++;
        
        voters[voteName][addr] = true;
        
        return "Vote successful casted!";

    }

    function voteResult(string memory voteName) public view returns( Candidate[] memory){
        
        require(bytes(voteName).length > 0, "Vote name cannot be empty");
        string[] memory candidates = candidateVote[voteName];
        Candidate[] memory result = new Candidate[](candidates.length);

        uint i;
        for(i=0;i<candidates.length;i++){

            string memory candidateName = candidates[i];
            uint votes =  voteCount[voteName][candidateName];
            
            result[i] = Candidate(candidateName, votes);

        }

        return result;

   }
}