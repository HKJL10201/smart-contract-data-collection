pragma solidity ^0.5.1;
import './Tools.sol';
contract Vote {
    address public owner;
    struct Candidate {
        string name;
        uint voteCount;
    }
    Candidate[] private candidates;
    mapping(address => bool) private voters;
    bool private voteStart = false;
    bool private voteEnd = false;
    modifier isOwner() {
        require (msg.sender == owner);
        _;
    }
    modifier voteStarted() {
        require (voteStart);
        _;
    }
    modifier voteNotStarted() {
        require (! voteStart);
        _;
    }
    modifier voteEnded() {
        require (voteEnd);
        _;
    }
    event votingStarted();
    event votingEnded();
    event specifyWinners(string);
    constructor() public {
        owner = msg.sender;
    }
    function addCandidate(string memory candidateName) public isOwner() voteNotStarted() {
        require (! isNameInserted(candidateName));
        Candidate memory _candidate;
        _candidate.name = candidateName;
        _candidate.voteCount = 0;
        candidates.push(_candidate);
    }
    function showCandidates() public view voteStarted() returns(string memory) {
        string memory str="";
        for(uint i; i < candidates.length; i++) {
            str = Tools.concatStrings(str, candidates[i].name);
            if (i != candidates.length - 1)
                str = Tools.concatStrings(str,",");
        }
        return(str);
    }
    function vote(uint candidateNumber) public voteStarted() {
        require (! voters[msg.sender]);
        candidates[candidateNumber].voteCount++;
        voters[msg.sender] = true;
    }
    function startVote() public isOwner() voteNotStarted() {
        require (candidates.length >= 2);
        voteStart = true;
        emit votingStarted();
    }
    function endVote() public isOwner() voteStarted() {
        require (! voteEnd);
        voteEnd = true;
        emit votingEnded();
        emit specifyWinners(showWinner());
    }
    function showState() public view returns(string memory) {
        if (voteStart)
            if (voteEnd)
                return('Voting ended.');
            else
                return('Voting started.');
        else
            return('Voting didn\'t start.');
    }
    function showWinner() public view voteEnded() returns(string memory) {
        uint maxVotes = 0;
        uint i;
        uint winnerCount=0;
        for (i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > maxVotes) {
                maxVotes = candidates[i].voteCount;
                winnerCount = 1;
            }
            else if (candidates[i].voteCount == maxVotes)
                winnerCount++;
        }
        string memory str = Tools.concatStrings("Votes: ", Tools.uint2str(maxVotes), "| Winners: ");
        uint j = 0;
        for (i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount == maxVotes) {
                j++;
                str = Tools.concatStrings(str, candidates[i].name);
                if (j < winnerCount)
                    str = Tools.concatStrings(str, ",");
            }
        }
        return(str);
    }
    function showVotes() public view voteEnded() returns(string memory) {
        string memory str="";
        for(uint i; i < candidates.length; i++) {
            str = Tools.concatStrings(str, candidates[i].name,":",Tools.uint2str(candidates[i].voteCount));
            if (i != candidates.length - 1)
                str = Tools.concatStrings(str,",");
        }
        return(str);
    }
    function isNameInserted(string memory name) private view returns(bool) {
        for (uint i=0; i < candidates.length; i++) {
            if (Tools.isStringsEqual(name,candidates[i].name))
                return(true);
        }
        return(false);
    }
}
