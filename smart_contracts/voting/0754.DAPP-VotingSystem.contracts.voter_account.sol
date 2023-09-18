pragma solidity >=0.5.0 <0.6.0;
contract VoterAccount {
	//using strings for *;
	struct Voter {
		address id;			//id of the voter
		uint launched;
		bool hasvoted;		//whether or not the voter has voted
		bool launch;
	}
	mapping (address => Voter) idToVoter;
	address[] member_id;
	mapping (address => bool) hasregistered;

	function _createNewVoter(address _adrs) public {
		if(hasregistered[_adrs] == false)
		{
			idToVoter[_adrs] = Voter(_adrs, 0, false, false);
			hasregistered[_adrs] = true;
			member_id.push(_adrs);
		}
	}
}
