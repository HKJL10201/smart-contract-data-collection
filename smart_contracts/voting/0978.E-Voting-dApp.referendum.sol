// Mostly for experimental purposes in the last few hours of the hackathon.
// sayNo() and sayYes() functions do not work. #TODO: Test why.

pragma solidity ^0.4.18;

contract Referendum {
    struct Result {
        uint yes;
        uint no;
        uint number;
    }

    struct Vote {
        bool hasVoted;
        bool answer;
    }

    mapping (address => Vote) votes;
    Result result;
    string public subject;
    address owner;

    function Referendum(string _subject) public {
        subject = _subject;
        owner = msg.sender;
        result = Result(0, 0, 0);
    }

    event HasVoted(address voter);

    function vote(bool answer) private returns (bool) {
        address voter = msg.sender;
        if(votes[voter].hasVoted) return false;
        else {
            if(answer) result.yes++;
            else result.no++;
            result.number++;
            votes[voter].answer = answer;
            votes[voter].hasVoted = true;
            HasVoted(voter);
            return true;
        }
    }

    function sayYes() public returns(bool) {
        return vote(true);
    }

    function sayNo() public returns(bool) {
        return vote(false);
    }

    function getResult() public view returns(uint, uint, uint) {
        return (result.yes, result.no, result.number);
    }

    function kill() public {
        if(owner == msg.sender) {
            selfdestruct(owner);
        }
    }
}