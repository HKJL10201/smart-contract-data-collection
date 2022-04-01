// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract FutureGov{
	mapping(address=>address) hasVotedTo;
	mapping(address=>uint) public totalVotes;

	struct Cand{address addr; string name;}
	Cand[] public candidates;
	mapping(address=>bool) isCandidate;
	 

	Cand currentLeader;
	
	function candidateRegister(string memory myName) external {
        require(bytes(myName).length <= 100 && bytes(myName).length >=0);
		require(!isCandidate[msg.sender]);
		
		candidates.push(Cand({addr: msg.sender, name: myName }));
		isCandidate[msg.sender] = true;
	}

	function vote(address myCandidate) external {
		require(isCandidate[myCandidate]);

		if(totalVotes[hasVotedTo[msg.sender]] > 0){
			totalVotes[hasVotedTo[msg.sender]]--;
		}
		totalVotes[myCandidate]++;

		hasVotedTo[msg.sender] = myCandidate;
	}

	function claimChange() external {
		currentLeader = candidates[0];
		
		for(uint i = 0; i<candidates.length; i++){
			if(totalVotes[candidates[i].addr] > totalVotes[currentLeader.addr]){
			    currentLeader = candidates[i];
			}
		}
	}
	
	function giveWinner() external view returns (address, string memory){
	    return (currentLeader.addr, currentLeader.name);
	}
}