pragma solidity ^0.5.0;

contract Election {

	struct Candidate {
		uint id;
		string name;
		uint countRank1;
		uint countRank2;
		uint countRank3;
		uint countRank4;
	}

	struct Message {
		uint id;
		string message_content;
	}

	mapping(address => bool) public voters;
	mapping(uint => Candidate) public candidates;
	mapping(uint => Message) public messages;
	mapping(address => uint) public stake;
	uint public candidatesCount;
	uint public messageCount;

	event votedEvent (
		uint indexed _rank1
	);
 
	constructor() public {
	addCandidate("Candidate 1");
	addCandidate("Candidate 2");
	addCandidate("Candidate 3");
	addCandidate("Candidate 4");
	}

	function addCandidate (string memory _name) private {
		candidatesCount ++;
		candidates[candidatesCount] = Candidate(candidatesCount, _name, 0 ,0 ,0 ,0);
	}

	function () external payable {
		deposit(); // Fallback function, accepts deposits
	}

	function deposit () public payable {
		stake[msg.sender] += msg.value;
	}

	function vote (uint _rank1, uint _rank2, uint _rank3, uint _rank4) public {
		require(!voters[msg.sender]); // Haven't voted before
		require(stake[msg.sender] > 0); // Have deposited ETH 
		require((_rank1 != _rank2) && (_rank1 != _rank3) && (_rank1 != _rank4) && (_rank2 != _rank3) && (_rank3 != _rank4)); // Do not vote for same candidate twice
		voters[msg.sender] = true; // Flag accountas having voted

		// Votes are equal to the deposited stake of ETH
		candidates[_rank1].countRank1 += (stake[msg.sender]/1e18); 
		candidates[_rank2].countRank2 += (stake[msg.sender]/1e18);
		candidates[_rank3].countRank3 += (stake[msg.sender]/1e18);
		candidates[_rank4].countRank4 += (stake[msg.sender]/1e18);

		// Set accounts deposited stake to 0
		stake[msg.sender] = 0;

		// Emit voted event signal
		emit votedEvent(_rank1);
	}

    function createmessage (string memory _message) public {
      messageCount++;
      messages[messageCount] = Message(messageCount, _message);
    }

}