pragma solidity ^0.4.11;

contract Election{
		
		struct Candidate{

			uint id;
			string name;
			uint votesCount;
		}

		//voters map
		mapping (address => bool) public voters;
		
		//data of election in a map
		mapping (uint => Candidate) public candidates;

		//to track no. of candidates
		uint public candidatesCount;

		event votedEvent(
			uint indexed _candidateId
		);

		function Election() public{
			addCandidate("BJP");
			addCandidate("INC");
			addCandidate("AAP");
		}

		function addCandidate (string _name) private {
			candidatesCount ++;
			candidates[candidatesCount]= Candidate(candidatesCount, _name, 0);
		}

		function vote (uint _candidateId) public {

			//first checking that voter has voted or not

			require (!voters[msg.sender] );

			//check valid candidate
			require (_candidateId > 0 && candidatesCount >= _candidateId);
			

			//add voter to list
			voters[msg.sender]=true;
			//update vote count in struct
			candidates[_candidateId].votesCount++;

			votedEvent(_candidateId);

			
		}
		
		
}