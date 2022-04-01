pragma solidity >=0.6.0;

contract Voting
{
	event Voted(address voter, address indexed candidate);

	mapping (address => bool) public voted;

	mapping (address => uint) public votesForCandidate;

	function vote(address candidate) public
	{
		require(voted[msg.sender] == false, "You must vote only one times!");

		votesForCandidate[candidate]++;
		voted[msg.sender] = true;

		emit Voted(msg.sender, candidate);
	}
}