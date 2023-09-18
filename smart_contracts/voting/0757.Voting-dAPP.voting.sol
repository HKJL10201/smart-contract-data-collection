// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FavoriteFruitsVoting {
    struct SessionInfo {
        string question;
        string[] options;
    }

    struct VoteCount {
        mapping (string => uint256) counts;
    }

    SessionInfo[] sessions;
    mapping (uint256 => VoteCount) voteCounts;

    function createSession(string memory _question, string[] memory _options) public {
        SessionInfo memory newSession = SessionInfo({
            question: _question,
            options: _options
        });
        sessions.push(newSession);
    }

    function vote(uint256 sessionId, string memory option) public {
        VoteCount storage count = voteCounts[sessionId];
        count.counts[option] += 1;
    }

    function getVoteCount(uint256 sessionId, string memory option) public view returns (uint256) {
        return voteCounts[sessionId].counts[option];
    }

    function getAllSessions() public view returns (SessionInfo[] memory) {
        return sessions;
    }

    function getSessionResults(uint256 sessionId) public view returns (string[] memory, uint256[] memory) {
        string[] memory optionNames = sessions[sessionId].options;
        uint256[] memory counts = new uint256[](optionNames.length);

        for (uint256 i = 0; i < optionNames.length; i++) {
            counts[i] = voteCounts[sessionId].counts[optionNames[i]];
        }

        return (optionNames, counts);
    }

    receive() external payable {
        // Обработка полученного tBNB
    }
    fallback() external {
        // Обработка транзакции
    }
}