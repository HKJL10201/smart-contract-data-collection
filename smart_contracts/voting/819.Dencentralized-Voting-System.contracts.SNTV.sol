pragma solidity ^0.8.0;

contract SingleNonTransferableVote {
    struct Poll {
        uint256 id;
        address creator;
        string title;
        string ipfsHash; // Metadata stored on IPFS
        uint256 optionCount;
        uint256[] voteCounts;
        bool ended;
        mapping(address => bool) hasVoted;
    }

    Poll[] public polls;

    event PollCreated(uint256 indexed pollId, address indexed creator);

    modifier onlyPollOwner(uint256 _pollId) {
        require(polls[_pollId].creator == msg.sender, "Not the poll owner.");
        _;
    }

    function createPoll(string memory _title, string memory _ipfsHash, uint256 _optionCount) public {
        Poll memory newPoll = Poll({
            id: polls.length,
            creator: msg.sender,
            title: _title,
            ipfsHash: _ipfsHash,
            optionCount: _optionCount,
            voteCounts: new uint256[](_optionCount),
            ended: false
        });
        polls.push(newPoll);
        emit PollCreated(newPoll.id, msg.sender);
    }

    function vote(uint256 _pollId, uint256 _optionIndex) public {
        require(!polls[_pollId].ended, "Poll has ended.");
        require(!polls[_pollId].hasVoted[msg.sender], "User has already voted.");
        require(_optionIndex < polls[_pollId].optionCount, "Invalid option index.");

        polls[_pollId].voteCounts[_optionIndex]++;
        polls[_pollId].hasVoted[msg.sender] = true;
    }

    function endPoll(uint256 _pollId) public onlyPollOwner(_pollId) {
        require(!polls[_pollId].ended, "Poll has already ended.");
        polls[_pollId].ended = true;
    }

    function getResults(uint256 _pollId) public view returns (uint256[] memory) {
        require(polls[_pollId].ended, "Poll has not ended.");
        return polls[_pollId].voteCounts;
    }

    function getPoll(uint256 _pollId) public view returns (Poll memory) {
        return polls[_pollId];
    }
}
