pragma solidity ^ 0.4 .24;

contract VotingDApp {
    struct Person {
        string ID;
        string name;
        bool Registered;
    }
    struct Candidate {
        string Party;
        uint256 Count;
        bool Registered;
    }
    event VotedFor(string pname, string ID, string message);
    event PartyVoteCount(string pname, uint256 count);
    event GeneralLogger(string message);
    mapping(string => Person) voters;
    mapping(string => Candidate) Parties;

    function Register(string ID, string name) public  returns(string message) {
        if (voters[ID].Registered) {
            message = "Already Registered";
            emit GeneralLogger(message);
            return message;
        }
        voters[ID] = Person(ID, name, true);
        message = "Registered";
        emit GeneralLogger(message);
        return message;
    }

    function RegisterCandidate(string name) public returns(string message) {
        if (Parties[name].Registered) {
            message = "Already Registered";
            emit GeneralLogger(message);
            return message;
        }
        Parties[name] = Candidate(name, 0, true);
        message = "Registered";
        emit GeneralLogger(message);
        return message;
    }

    function Vote(string pname, string ID) public  returns(string message) {
        if (!Parties[pname].Registered) {
            message = "Party not registered";
            emit VotedFor(pname, ID, message);
            return message;
        }
        Parties[pname].Count++;
        message = "Vote for candidate";
        emit VotedFor(pname, ID, message);
        return message;
    }

    function Count(string pname) public returns(uint count) {
        if (!Parties[pname].Registered) {
            count = 0;
            emit PartyVoteCount(pname,count);
            return count;
        }
        count = Parties[pname].Count;
        emit PartyVoteCount(pname,count);
        return count;
    }
}