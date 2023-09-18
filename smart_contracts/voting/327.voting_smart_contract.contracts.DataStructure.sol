pragma solidity ^0.5.16;

contract DataStructure {

    struct votingCandidate {
        string name;
        string id;
        string group;
        bool active;
    }

    struct votingEvent {
        bytes32 eventID;
        string eventName;
        uint dateStart;
        uint dateEnd;
        string location;
        string extra;
    }

    struct voter {
        string name;
        string id;
        bool active;
    }

    struct votingResult {
        uint count;
    }

    struct voting {
        votingEvent evt;
        address[] candidateAddr;
        address[] voterAddr;
        mapping(address => votingResult) voteResults;
    }

    mapping(address => votingCandidate) public regCandidates;    
    mapping(address => voter) public regVoters;
    mapping(bytes32 => voting) internal regEvents;

    address[] public candidatesList;
    address[] public votersList;
    
    address public owner;

}