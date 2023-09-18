pragma solidity ^0.8.0;

contract AlternativeVotingSystem {
    struct Poll {
        uint256 id;
        address creator;
        string title;
        string ipfsHash; // Metadata stored on IPFS
        uint256 optionCount;
        bool ended;
        uint256[] eliminated;
        mapping(address => bool) hasVoted;
        mapping(address => uint256[]) votes;
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
            ended: false,
            eliminated: new uint256[](0)
        });
        polls.push(newPoll);
        emit PollCreated(newPoll.id, msg.sender);
    }

    function vote(uint256 _pollId, uint256[] memory _rankedOptions) public {
        require(!polls[_pollId].ended, "Poll has ended.");
        require(!polls[_pollId].hasVoted[msg.sender], "User has already voted.");
        require(_rankedOptions.length == polls[_pollId].optionCount, "Invalid number of ranked options.");
        
        for(uint256 i = 0; i < _rankedOptions.length; i++) {
            require(_rankedOptions[i] < polls[_pollId].optionCount, "Invalid option index.");
            for(uint256 j = i + 1; j < _rankedOptions.length; j++) {
                require(_rankedOptions[i] != _rankedOptions[j], "Duplicate option index.");
            }
        }

        polls[_pollId].votes[msg.sender] = _rankedOptions;
        polls[_pollId].hasVoted[msg.sender] = true;
    }

    function endPoll(uint256 _pollId) public onlyPollOwner(_pollId) {
        require(!polls[_pollId].ended, "Poll has already ended.");
        polls[_pollId].ended = true;
    }

    function getResults(uint256 _pollId) public view returns (uint256 winner) {
        require(polls[_pollId].ended, "Poll has not ended.");

        uint256[] memory voteCounts = new uint256[](polls[_pollId].optionCount);

        while (winner == 0) {
            // Reset vote counts
            for (uint256 i = 0; i < voteCounts.length; i++) {
                voteCounts[i] = 0;
            }

            // Count votes
            for (uint256 i = 0; i < polls[_pollId].optionCount; i++) {
                bool eliminated = false;
                for (uint256 j = 0; j < polls[_pollId].eliminated.length; j++) {
                    if (i == polls[_pollId].eliminated[j]) {
                        eliminated = true;
                        break;
                    }
                }

                if (!eliminated) {
                    for (uint256 j = 0; j < polls[_pollId].optionCount; j++) {
                        if (polls[_pollId].votes[msg.sender][j] == i) {
                            voteCounts[i]++;
                            break;
                           }
                }
            }
        }

        // Find the minimum number of votes
        uint256 minVotes = type(uint256).max;
        for (uint256 i = 0; i < voteCounts.length; i++) {
            bool eliminated = false;
            for (uint256 j = 0; j < polls[_pollId].eliminated.length; j++) {
                if (i == polls[_pollId].eliminated[j]) {
                    eliminated = true;
                    break;
                }
            }

            if (!eliminated && voteCounts[i] < minVotes) {
                minVotes = voteCounts[i];
            }
        }

        // Check if there's a winner
        for (uint256 i = 0; i < voteCounts.length; i++) {
            if (voteCounts[i] * 2 > polls.length) {
                winner = i;
                break;
            }
        }

        // If there's no winner, eliminate the candidate(s) with the least votes
        if (winner == 0) {
            for (uint256 i = 0; i < voteCounts.length; i++) {
                if (voteCounts[i] == minVotes) {
                    polls[_pollId].eliminated.push(i);
                }
            }
        }
    }

    return winner;
}

function getPoll(uint256 _pollId) public view returns (Poll memory) {
    return polls[_pollId];
}
