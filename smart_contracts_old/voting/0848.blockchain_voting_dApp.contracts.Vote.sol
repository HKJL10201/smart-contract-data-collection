pragma solidity ^0.5.0;

contract Vote {
	
	struct Person {
		uint i;
		uint vote;
		address voter;
	}

	Person[] persons;
	uint[] public votes;
	address[] public voters;

	event PersonAdded(uint indexed id, uint vote, address voter);
	
	// record votes using the addPerson function
	function addPerson(uint _vote) public returns (uint vote) {

		address voter = msg.sender;
		bool alreadyVoted = false;
		uint index = 0; 
		
		// check to see if this address has already voted
		for(uint i=0; i<persons.length; i++) {	
			if (persons[i].voter == voter) {
				alreadyVoted = true;
				index = i;
			} 
		}
		
		// Throw an error if the voter has already voted
		require(alreadyVoted == false, "Sorry, you have already voted.");
		
		
		// voters can choose between two colors: voteId 0 is blue; voteId 1 is red
		// ensure the vote is being place for one of these two colors
		require(_vote >= 0 && _vote <= 1, "Vote is not 0 or 1");


		// Add vote & emit event
		Person memory person = Person(index, _vote, voter);

        persons.push(person);

		emit PersonAdded(index, _vote, voter);

		return _vote;

	}


	// retrieve the vote counts
	function getVoteCounts() public view returns (uint blueVotes, uint redVotes) {

		uint blue = 0;
		uint red = 0;

		for(uint i=0; i<persons.length; i++) {
			if (persons[i].vote == 0) {
				blue++;
			} else if (persons[i].vote == 1) {
				red++;
			}
		}

		return (blue, red);
	
	} 

}