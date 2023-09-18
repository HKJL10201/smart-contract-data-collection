pragma solidity ^0.5.0;

contract VotingApp {
    struct Candidate {
        bool isExist;
        uint votes;
    }

    struct Voter {
        bool isExist;
        address candidate;
    }

    mapping (address => Candidate) candidates;
    address[] candidatesAddresses;
    mapping (address => Voter) voters;
    address[] votersAddresses;
    uint amountOfVotesForEnd;
    uint candidatesAmount;

    constructor(uint _amountOfVotesForEnd, uint _candidatesAmount) public {
        amountOfVotesForEnd = _amountOfVotesForEnd;
        candidatesAmount = _candidatesAmount;
    }

    modifier onlyVoter() {
        require(voters[msg.sender].isExist);
        _;
    }

    modifier onlyCandidate() {
        require(candidates[msg.sender].isExist);
        _;
    }

    modifier onlyWhenCandidatesFullfilled() {
        require(candidatesAddresses.length == candidatesAmount);
        _;
    }

    modifier onlyWhenCandidatesNotFullfilled() {
        require(candidatesAddresses.length < candidatesAmount);
        _;
    }

    modifier onlyWithoutRole() {
        require(!voters[msg.sender].isExist && !candidates[msg.sender].isExist);
        _;
    }

    modifier onlyVotingEnded() {
        require(amountOfVotesForEnd == 0);
        _;
    }

    function becomeCandidate() public onlyWithoutRole onlyWhenCandidatesNotFullfilled returns (bool) {
        candidatesAddresses.push(msg.sender);
        candidates[msg.sender].isExist = true;
        return true;
    }

    function getCandidates() public view returns (address[] memory) {
        return candidatesAddresses;
    }

    function becomeVoter() public onlyWithoutRole returns (bool) {
        votersAddresses.push(msg.sender);
        voters[msg.sender].isExist = true;
        return true;
    }

    function getVotesAmount() public view onlyCandidate returns (uint) {
        return candidates[msg.sender].votes;
    }

    function voteForCandidate(address _candidate) onlyWhenCandidatesFullfilled public onlyVoter returns(bool) {
        if(amountOfVotesForEnd == 0 || voters[msg.sender].candidate != address(0)) return false;
        voters[msg.sender].candidate = _candidate;
        candidates[_candidate].votes++;
        amountOfVotesForEnd--;
        return true;
    }

    function getVotesForCandidates(address _candidate) public view onlyVotingEnded returns(uint) {
        return candidates[_candidate].votes;
    }

    function checkRole() public view returns (string memory) {
        if(voters[msg.sender].isExist) return "voter";
        if(candidates[msg.sender].isExist) return "candidate";
        else return "null";
    }

    function getVotedCandidate() public onlyVoter view returns (address) {
        return voters[msg.sender].candidate;
    }

    function isVotingEnded() public view returns (bool) {
        if(amountOfVotesForEnd == 0) return true;
        return false;
    }

    function isCondidatesFullfilled() public view returns (bool) {
        if(candidatesAddresses.length == candidatesAmount) return true;
        return false;
    }

    function getVotingResult() public view onlyVotingEnded returns (address[] memory, uint[] memory) {
        uint[] memory candidateVotes = new uint[](candidatesAddresses.length);

        for(uint i = 0; i < candidatesAddresses.length; i++) {
            candidateVotes[i] = candidates[candidatesAddresses[i]].votes;
        }

        return (candidatesAddresses, candidateVotes);
    }
}
