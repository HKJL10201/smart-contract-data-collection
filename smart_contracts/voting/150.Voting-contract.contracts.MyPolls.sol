// SPDX-License-Identifier: MIT
pragma solidity = 0.8.9; 

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import 'erc721a/contracts/ERC721A.sol';

contract MyPolls is Pausable, Ownable {
    
    struct candidate {
        string _name;
        uint _votesGot;
    }

    uint8 votsCount;
    address[] votters;
    address[] candidatesArray;
    mapping (address => candidate) public candidates;
    
    event CandidateAdded(uint count, string name);
    event NewVotAdded(uint count, string name);


    constructor () {  
        votsCount = 0;   
        pause();
    }

    // --- Pauses the voting process --- \\
    function pause() public onlyOwner {
        _pause();
    }

    // --- Unpauses the voting process --- \\
    function unpause() public onlyOwner {
        _unpause();
    }

    // --- This registers a new candidate --- \\
    function addCandidate (address candAdress, string memory name ) public onlyOwner {
        require(!paused(), "Contract is paused");
        candidatesArray.push(candAdress);
        candidates[candAdress] = candidate(name, 0);

        console.log("Candidate %s is added at index %s", name, candAdress);       
        emit CandidateAdded(candidatesArray.length, name);
    }

    // --- Votting function by votters ---\\
    function vote(address _candAddress) public {
        // chech if not paused
        // check if candidate exists
        // check if votter already votted
        // increment total vote count
        // increament votesGot
        // add votter to list
        // emit votting event

        require(!paused(), "Contract is paused");
        require(candidateExists(_candAddress), "Unknown candidate");
        require(notVottedBefore(msg.sender), "votter already votted");

        candidates[_candAddress]._votesGot ++;
        votsCount++;
        votters.push(msg.sender);
        console.log("Votter %s has votted", msg.sender);
    } 

    function candidateExists(address _candAddress) public view returns (bool){
        for(uint i=0; i<candidatesArray.length; i++){
            if (candidatesArray[i]==_candAddress){
                return true;
            }
        }
        return false;
    }

    function notVottedBefore(address _votterAddress) public view returns (bool){
        for(uint i=0; i<votters.length; i++){
            if (votters[i]==_votterAddress){
                return false;
            }
        }
        return true;
    }
    

    // --- Returns the number of candidates registered --- \\
    function getCandidatesCount() public view returns (uint){
        return candidatesArray.length; 
    }

    // --- Returns the number of ppl votted so far --- \\
    function getVotCount() public view returns (uint){
        return votsCount; 
    }
}