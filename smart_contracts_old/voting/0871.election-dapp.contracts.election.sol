pragma solidity ^0.5.0;

contract election
{
	struct candidate
	{
		uint id;
		string name;
		uint votes;
	}

	mapping(uint =>  candidate) public candidates;
	mapping(address => bool) public voters;

	uint public count;
	
	function add_candidate(string memory _name) private
	{
		count++;
		candidates[count] = candidate(count, _name, 0);
	}

	constructor() public
	{
		add_candidate("Candidate 1");
		add_candidate("Candidate 2");
	}

	function vote(uint candidate_id) public
	{
		require(!voters[msg.sender]);
		require((candidate_id > 0) && (candidate_id <= count));

		voters[msg.sender] = true;
		candidates[candidate_id].votes++;
		emit votedEvent(candidate_id);
	}

	event votedEvent 
	(
        	uint indexed _candidateId
    	);
}
