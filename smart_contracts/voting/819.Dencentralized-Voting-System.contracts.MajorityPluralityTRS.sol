pragma solidity ^0.8.0;

contract MajorityPluralityTRS {
    struct Poll {
        uint256 id;
        address creator;
        string title;
        string ipfsHash; // Metadata stored on IPFS
        uint256 optionCount;
        uint256[] voteCounts;
        uint256 round;
        bool ended;
        mapping(address => bool) hasVoted;
        mapping(uint256 => bool) eliminated;
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
            round: 1,
            ended: false
        });
        polls.push(newPoll);
        emit PollCreated(newPoll.id, msg.sender);
    }

    function vote(uint256 _pollId, uint256 _optionIndex) public {
        require(!polls[_pollId].ended, "Poll has ended.");
        require(!polls[_pollId].hasVoted[msg.sender], "User has already voted.");
        require(_optionIndex < polls[_pollId].optionCount, "Invalid option index.");
        require(!polls[_pollId].eliminated[_optionIndex], "Selected option is eliminated.");

        polls[_pollId].voteCounts[_optionIndex]++;
        polls[_pollId].hasVoted[msg.sender] = true;
    }

    function endRound(uint256 _pollId) public onlyPollOwner(_pollId) {
        require(!polls[_pollId].ended, "Poll has already ended.");
        require(polls[_pollId].round <= 2, "Only 2 rounds are allowed.");

        uint256 maxVotes = 0;
        uint256 maxIndex = 0;
        uint256 secondMaxVotes = 0;
        uint256 secondMaxIndex = 0;

        for (uint256 i = 0; i < polls[_pollId].optionCount; i++) {
            if (polls[_pollId].voteCounts[i] > maxVotes) {
                secondMaxVotes = maxVotes;
                secondMaxIndex = maxIndex;
                maxVotes = polls[_pollId].voteCounts[i];
                maxIndex = i;
            } else if (polls[_pollId].voteCounts[i] > secondMaxVotes) {
                secondMaxVotes = polls[_pollId].voteCounts[i];
                secondMaxIndex = i;
            }
        }

        if (polls[_pollId].round == 1) {
            // Eliminate all candidates except the top two.
            for (uint256 i = 0; i < polls[_pollId].optionCount; i++) {
                if (i != maxIndex && i != secondMaxIndex) {
                    polls[_pollId].eliminated[i] = true;
                }
            }

            // Reset voters and advance to the second round
            for (uint256 i = 0; i < polls[_pollId].optionCount; i++) {
                polls[_pollId].voteCounts[i] = 0;
            }
            polls[_pollId].round = 2;
            resetVoters
            (_pollId);
          } else if (polls[_pollId].round == 2) {
          // Declare the winner after the second round.
          polls[_pollId].ended = true;
          }
        }
function resetVoters(uint256 _pollId) private {
    for (uint256 i = 0; i < polls.length; i++) {
        polls[_pollId].hasVoted[msg.sender] = false;
    }
}

function getResults(uint256 _pollId) public view returns (uint256[] memory) {
    require(polls[_pollId].ended, "Poll has not ended.");
    return polls[_pollId].voteCounts;
}

function getPoll(uint256 _pollId) public view returns (Poll memory) {
    return polls[_pollId];
}
