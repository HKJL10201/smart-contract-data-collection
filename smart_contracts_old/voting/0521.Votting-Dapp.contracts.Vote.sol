pragma solidity >=0.4.21 <0.7.0;
// APS 1050 PROJECT
// D-VOTING
// YANGFAN LI
// 1003152982

// Simple event
contract EvenVote {

	struct Proposal {
		string title;
		string content;
		uint vote_count;
		string options;
		uint option1count1;
		uint option1count2;
		uint option1count3;
		bool started;
		uint idx;
	}

	mapping(uint=>Proposal) public proposals;
	mapping(uint=>mapping(address=>bool)) public voted_map;
	uint public vote_num = 1;

	function add_proposal(string memory title, string memory body, string memory _options) public {
		proposals[vote_num].title = title;
		proposals[vote_num].content = body;
		proposals[vote_num].vote_count = 0;
		proposals[vote_num].started = true;
		proposals[vote_num].options = _options;
		proposals[vote_num].option1count1 = 0;
		proposals[vote_num].option1count2 = 0;
		proposals[vote_num].option1count3 = 0;
		proposals[vote_num].idx = vote_num;
		++vote_num;
	}

	function vote(uint _id, uint option) public {
		require(proposals[_id].started, "NA");
		require(!voted_map[_id][msg.sender], "Voted");
		require(option < 3, "Invalid option");

		if (option == 0) {
			proposals[_id].option1count1 += 1;
		} else if (option == 1) {
			proposals[_id].option1count2 += 1;
		} else if (option == 2) {
			proposals[_id].option1count3 += 1;
		}

		proposals[_id].vote_count += 1;
		voted_map[_id][msg.sender] = true;
	}
}

// Event weight vote with block constraint
contract EvenWithBlockVote is EvenVote() {

	mapping(uint=>uint) public block_required;

	function add_proposal(string memory title, string memory body, string memory _options, uint block_num) public {
		proposals[vote_num].title = title;
		proposals[vote_num].content = body;
		proposals[vote_num].vote_count = 0;
		proposals[vote_num].started = true;
		proposals[vote_num].options = _options;
		proposals[vote_num].option1count1 = 0;
		proposals[vote_num].option1count2 = 0;
		proposals[vote_num].option1count3 = 0;
		block_required[vote_num] = block_num;
		proposals[vote_num].idx = vote_num;
		++vote_num;
	}

	function vote(uint _id, uint option, uint _block) public {
		require(proposals[_id].started, "NA");
		require(!voted_map[_id][msg.sender], "Voted");
		require(option < 3, "Invalid option");
		require(_block < block_required[_id], "Cannot vote");

		if (option == 0) {
			proposals[_id].option1count1 += 1;
		} else if (option == 1) {
			proposals[_id].option1count2 += 1;
		} else if (option == 2) {
			proposals[_id].option1count3 += 1;
		}

		proposals[_id].vote_count += 1;
		voted_map[_id][msg.sender] = true;
	}
}

// Event weight vote with balance constraint
contract EvenWithMinBalanceVote is EvenVote() {

	mapping(uint=>uint) public min_balance;

	function add_proposal(string memory title, string memory body, string memory _options, uint min_b) public {
		proposals[vote_num].title = title;
		proposals[vote_num].content = body;
		proposals[vote_num].vote_count = 0;
		proposals[vote_num].started = true;
		proposals[vote_num].options = _options;
		proposals[vote_num].option1count1 = 0;
		proposals[vote_num].option1count2 = 0;
		proposals[vote_num].option1count3 = 0;
		proposals[vote_num].idx = vote_num;
		min_balance[vote_num] = min_b;
		++vote_num;
	}

	function vote(uint _id, uint option) public {
		require(proposals[_id].started, "NA");
		require(!voted_map[_id][msg.sender], "Voted");
		require(option < 3, "Invalid option");
		require(msg.sender.balance > min_balance[_id], "Cannot vote");

		if (option == 0) {
			proposals[_id].option1count1 += 1;
		} else if (option == 1) {
			proposals[_id].option1count2 += 1;
		} else if (option == 2) {
			proposals[_id].option1count3 += 1;
		}

		proposals[_id].vote_count += 1;
		voted_map[_id][msg.sender] = true;
	}
}

// Balance weight vote
contract BalanceVote is EvenVote() {

	function vote(uint _id, uint option) public {
		require(proposals[_id].started, "NA");
		require(!voted_map[_id][msg.sender], "Voted");
		require(option < 3, "Invalid option");

		if (option == 0) {
			proposals[_id].option1count1 += msg.sender.balance / (1 ether);
		} else if (option == 1) {
			proposals[_id].option1count2 += msg.sender.balance / (1 ether);
		} else if (option == 2) {
			proposals[_id].option1count3 += msg.sender.balance / (1 ether);
		}

		proposals[_id].vote_count +=1;
		voted_map[_id][msg.sender] = true;
	}
}

// Balance weight vote with block constraint
contract BalanceWithBlockVote is EvenWithBlockVote() {

	function vote(uint _id, uint option, uint _block) public {
		require(proposals[_id].started, "NA");
		require(!voted_map[_id][msg.sender], "Voted");
		require(option < 3, "Invalid option");
		require(_block < block_required[_id], "Cannot vote");

		if (option == 0) {
			proposals[_id].option1count1 += msg.sender.balance / (1 ether);
		} else if (option == 1) {
			proposals[_id].option1count2 += msg.sender.balance / (1 ether);
		} else if (option == 2) {
			proposals[_id].option1count3 += msg.sender.balance / (1 ether);
		}

		proposals[_id].vote_count += 1;
		voted_map[_id][msg.sender] = true;
	}
}

// Balance weight vote with balance constraint
contract BalanceWithMinBalanceVote is EvenWithMinBalanceVote() {

	function vote(uint _id, uint option) public {
		require(proposals[_id].started, "NA");
		require(!voted_map[_id][msg.sender], "Voted");
		require(option < 3, "Invalid option");
		require(msg.sender.balance > min_balance[_id], "Cannot vote");

		if (option == 0) {
			proposals[_id].option1count1 += msg.sender.balance / (1 ether);
		} else if (option == 1) {
			proposals[_id].option1count2 += msg.sender.balance / (1 ether);
		} else if (option == 2) {
			proposals[_id].option1count3 += msg.sender.balance / (1 ether);
		}

		proposals[_id].vote_count += 1;
		voted_map[_id][msg.sender] = true;
	}
}
