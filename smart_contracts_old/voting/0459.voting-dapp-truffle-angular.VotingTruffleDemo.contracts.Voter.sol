pragma solidity ^0.4.11;

contract Voter {
    mapping(bytes32 => candidate) candidateMap;								// Maps candidate address with candidate struct
    
	// Structure to get data for a candidate
	struct candidate {
	    bytes32 candidateAddress;											// Candidate Address (For simplicity, I am taking bytes32)
		bytes32 firstName;													// Candidate First Name
		bytes32 lastName;													// Candidate Last Name
		uint256 voteCount;													// Candidate Vote Count
		bool candidateType;													// Candidate Type (Voter or Participent)
		bool voted;															// Candidate Voted or not
	}
	
	candidate[] candidateList;												// Array of candidates
	
	// Address of owner of the contract
	// Will be used to kill the contract later if required
	address creator;
	
	// Constructor : Sets creator variable
	function Voter() {
		creator = msg.sender;
	}
	
	// Function to create a candidate
	// Checks if candidate doesn't exist
	// makes candidate type as true or false based on the parameter passed to it
	
	function createCandidate(bytes32 _candidateAddress, bytes32 _firstName, bytes32 _lastName, bytes32 _candidateType) {
		assert(candidateMap[_candidateAddress].candidateAddress == 0);
		candidateMap[_candidateAddress].candidateAddress = _candidateAddress;
		candidateMap[_candidateAddress].firstName = _firstName;
		candidateMap[_candidateAddress].lastName = _lastName;
		candidateMap[_candidateAddress].voteCount = 0;
		if(_candidateType == "Candidate") {
		    candidateMap[_candidateAddress].candidateType = true;
		} else if(_candidateType == "Voter") {
		    candidateMap[_candidateAddress].candidateType = false;
		} else { throw; }
		candidateMap[_candidateAddress].voted = false;							// Voted flag set false for new candidate
		candidateList.push(candidateMap[_candidateAddress]);
	}
	
	// This function will return the list of all the candidates
	// This is a getter function and hence should not consume any gas
	// All the properties of the sturct "candidate" is returned seperately because structure can't be returned in Solidity
	
	function getCandidateList() constant returns (bytes32[], bytes32[], bytes32[], uint256[], bool[], bool[]) {
		uint256 arrLength = 0;
	    
	    for(uint256 i1=0; i1<candidateList.length; i1++) {
	        if(candidateList[i1].candidateType) {
	            arrLength++;
	        }
	    }
	    
	    //uint256 arrLength = candidateList.length;
	    bytes32[] memory candidateAddresses = new bytes32[](arrLength);
	    bytes32[] memory fNames = new bytes32[](arrLength);
	    bytes32[] memory lNames = new bytes32[](arrLength);
	    uint256[] memory voteCounts = new uint256[](arrLength);
	    bool[] memory candidateType = new bool[](arrLength);
	    bool[] memory voted = new bool[](arrLength);
		bytes32 tmpAddr;
	    for(uint256 i=0; i<arrLength; i++) {
	        if(candidateList[i].candidateType) {
	            tmpAddr = candidateList[i].candidateAddress;
    	        candidateAddresses[i] = candidateMap[tmpAddr].candidateAddress;
    	        fNames[i] = candidateMap[tmpAddr].firstName;
    	        lNames[i] = candidateMap[tmpAddr].lastName;
    	        voteCounts[i] = candidateMap[tmpAddr].voteCount;
				//voteCount = candidateMap[_candidateAddress].voteCount;
    	        candidateType[i] = candidateMap[tmpAddr].candidateType;
    	        voted[i] = candidateMap[tmpAddr].voted;
	        }
	    }
	    return(candidateAddresses, fNames, lNames, voteCounts, candidateType, voted);
	}
	
	// This function will return detail of a specific candidate
	// It requires candidate address as input parameter
	
	function getCandidateDetail(bytes32 _candidateAddress) constant returns (bytes32, bytes32, bytes32, uint256, bool, bool) {
	    bytes32 candiateAddress = candidateMap[_candidateAddress].candidateAddress;
	    bytes32 fName = candidateMap[_candidateAddress].firstName;
	    bytes32 lName = candidateMap[_candidateAddress].lastName;
	    uint256 voteCount = candidateMap[_candidateAddress].voteCount;
	    bool candidateType = candidateMap[_candidateAddress].candidateType;
	    bool voted = candidateMap[_candidateAddress].voted;
	    return (candiateAddress, fName, lName, voteCount, candidateType, voted);
	}
	
	// This function will be used to vote
	
	function voteForCandidate(bytes32 _candidateAddress, bytes32 _voterAddress) {
	    //assert(validateVoter(_voterAddress));
	    candidateMap[_candidateAddress].voteCount += 1;
	    candidateMap[_voterAddress].voted = true;
	}
	
	// This function will validate the voter if exists and
	// whether Voter has already voted or not
	// Not being used as of now
	
	function validateVoter(bytes32 _voterAddress) constant returns (bool success) {
	    assert(candidateMap[_voterAddress].candidateAddress != 0);
	    assert(candidateMap[_voterAddress].voted != true);						
	    return true;
	}
	
	// Kill the contract
	// Should be implemented with onlyOwner modifier
	// For simplicity, I have not implemented any modifier in this contract
	
	function kill() {
		if(msg.sender == creator) {
			suicide(creator);
		}
	}
	
	
	
}
