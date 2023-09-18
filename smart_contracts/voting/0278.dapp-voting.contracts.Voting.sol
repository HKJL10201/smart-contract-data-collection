// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Strings.sol";

contract Voting {
    using Strings for uint256;

    event SessionCreated(string topic, string[] options);

    struct VotingSession {
        string topic;
        string[] optionNames;
        mapping(string => uint) options;
        mapping(string => bool) optionExist;
        mapping(address => bool) voted;
    }

    VotingSession[] votingSessions;
    mapping(int => string) sessionList;
    int currentSessionId = 0;

    function createSession(string memory _topic, string[] memory _options) external {
        require(_options.length > 0, "You should provide at least 1 option");
        VotingSession storage session = votingSessions.push();
        session.topic = _topic;
        for(uint i=0; i < _options.length; i++){
            session.options[_options[i]] = 0;
            session.optionExist[_options[i]] = true;
        }
        session.optionNames = _options;
        currentSessionId+=1;
        sessionList[currentSessionId-1] = _topic;

        emit SessionCreated(_topic, _options);
    }

    function vote(string calldata option) external {
        require(votingSessions.length > 0, "Sorry, there are no voting sessions at this time");
        VotingSession storage session = votingSessions[uint(currentSessionId-1)];
        require(session.optionExist[option], "Sorry, this option is not allowed");
        require(!session.voted[msg.sender], "You have already voted");
        session.voted[msg.sender] = true;
        session.options[option] += 1;
    }

    function getVoteResults() public view virtual returns(string memory)  {
        require(votingSessions.length > 0, "Sorry, there are no voting sessions at this time");
        return concatVoteResults(currentSessionId-1);
    }

    function getVoteResultsBySessionId(int id) public view virtual returns(string memory)  {
        require(votingSessions.length > 0, "Sorry, there are no voting sessions at this time");
        require(id >= 0, "Id should be positive");
        require(id <= currentSessionId-1, "There is no session with such Id");
        return concatVoteResults(id);
    }

    function getSessionsList() public view virtual returns(string memory)  {
        string memory result = "";
        for(uint i=0; i < votingSessions.length; i++){
            result = string.concat(result, Strings.toString(i),":", votingSessions[i].topic, ";");
        }
        return result;
    }

    function concatVoteResults(int id) internal view returns (string memory) {
        string memory result = "";
        VotingSession storage session = votingSessions[uint(id)];
        for(uint i=0; i < session.optionNames.length; i++){
            string memory optionName = session.optionNames[i];
            result = string.concat(result, optionName, ":", Strings.toString(session.options[optionName]), ";");
        }
        return result;
    }

    receive() external payable {}

}
