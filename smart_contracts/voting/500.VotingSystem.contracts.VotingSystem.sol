pragma solidity ^0.8.0;

contract VotingSystem {
    struct Voter {
        bool hasVoted;
        uint votedCandidate;
        mapping(uint => bool) votedBills;
    }

    struct Candidate {
        string name;
        uint voteCount;
    }

    struct Bill {
        string title;
        uint yesCount;
        uint noCount;
    }

    address public owner;
    mapping(address => Voter) public voters;
    Candidate[] public candidates;
    Bill[] public bills;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    function addCandidate(string memory _name) public onlyOwner {
        candidates.push(Candidate(_name, 0));
    }

    function addBill(string memory _title) public onlyOwner {
        bills.push(Bill(_title, 0, 0));
    }

    function registerVoter() public {
        Voter storage voter = voters[msg.sender];
        require(!voter.hasVoted, "Voter already registered");
        voter.hasVoted = false;
    }

    function getVoterAddress() public view returns (address) {
        return msg.sender;
    }

    function voteForCandidate(uint _candidateId) public {
        Voter storage voter = voters[msg.sender];
        require(!voter.hasVoted, "Voter has already voted for a candidate");
        require(_candidateId < candidates.length, "Invalid candidate ID");

        voter.hasVoted = true;
        voter.votedCandidate = _candidateId;
        candidates[_candidateId].voteCount++;
    }

    function voteForBill(uint _billId, bool _vote) public {
        Voter storage voter = voters[msg.sender];
        require(!voter.votedBills[_billId], "Voter has already voted for this bill");
        require(_billId < bills.length, "Invalid bill ID");

        voter.votedBills[_billId] = true;

        if (_vote) {
            bills[_billId].yesCount++;
        } else {
            bills[_billId].noCount++;           
        }
    }

    function hasVotedForBill(address _voter, uint _billId) public view returns (bool) {
    return voters[_voter].votedBills[_billId];
    }

    function getCandidatesCount() public view returns (uint) {
        return candidates.length;
    }

    function getCandidateNames() public view returns (string[] memory) {
    string[] memory candidateNames = new string[](candidates.length);

    for (uint i = 0; i < candidates.length; i++) {
        candidateNames[i] = candidates[i].name;
    }

    return candidateNames;
    }

    function getWinner() public view returns (string memory) {
        uint highestVotes = 0;
        string memory winnerName;

        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > highestVotes) {
                highestVotes = candidates[i].voteCount;
                winnerName = candidates[i].name;
            }
        }

    return winnerName;
    }


}