pragma solidity ^0.4.0;

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract Ballot is owned {
    struct Vote {
        uint8[5] points;
        address voter;
    }

    struct Project {
        string name;
        uint8[5] points;
        Vote[] votes;
        mapping (address => bool) voted;
    }

    Project[] public projects;
    uint public projectsCount;

    event ProjectAdded(uint projectID, string name);
    event Voted(uint projectID, uint8[5] points, address voter);

    mapping(address => string) fbIdByAddress;
    mapping(string => address) addressByFbId;
    function saveFacebookId(string fbID) {
      fbIdByAddress[msg.sender] = fbID;
      addressByFbId[fbID] = msg.sender;
    }

    function addProject(string name) onlyOwner returns (uint projectID) {
        projectID = projects.length++;
        Project p = projects[projectID];
        p.name = name;
        projectsCount = projects.length;
        ProjectAdded(projectID, name);
    }

    function vote(uint projectID, uint8[5] points) returns (uint voteID) {
        Project p = projects[projectID];
        if (p.voted[msg.sender] == true) throw;

        voteID = p.votes.length++;
        Vote v = p.votes[voteID];

        for (var i = 0; i < 5; ++i) {
            p.points[i] += points[i];
            v.points[i] = points[i];
        }
        p.voted[msg.sender] = true;
    }

    function getVotesCount(uint projectID) constant returns (uint votesCount) {
        Project p = projects[projectID];
        votesCount = p.votes.length;
    }

    function getPoints(uint projectID) constant returns (uint8[5] points) {
        Project p = projects[projectID];
        points = p.points;
    }
}

