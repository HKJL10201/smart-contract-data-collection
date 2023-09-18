pragma solidity ^0.4.11;

contract Election {
   struct Candidate {
	  uint id;
		string name;
		uint voteCount;
	 }
	 mapping(uint => Candidate) public candidates;
	 mapping(address => bool) public voters;
	 uint public candidatesCount;

	 function Election () public {
	    addCandidate("Candidate1");
			addCandidate("Candidate2");
	 }

	 function addCandidate(string _name) private {
	 candidatesCount++;
	 candidates[candidatesCount] = Candidate(candidatesCount,_name,0);
	 }

	 function addVote (uint candidateid) public {
	//  require(!voters[msg.sender]);
	 require(candidateid > 0 && candidateid <= candidatesCount);
	 voters[msg.sender] = true;
	 candidates[candidateid].voteCount++;
	 }
}