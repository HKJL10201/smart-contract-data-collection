pragma solidity >=0.5.0 <0.7.0;


contract Voting {
    /* <------ VARIABLES ------>*/
    struct Candidate {
        uint256 id_candidate;
        string name;
        uint256 voteCount;
    }
    mapping(uint256 => Candidate) public candidates;
    uint256 public candidateCount;

    struct Voter {
        uint256 id_voter;
        address voter_address;
        address delegate;
        bool authorized;
        uint256 weight;
        uint256 vote;
        bool voted;
    }
    mapping(uint256 => Voter) public voters;
    mapping(address => Voter) public votersList;

    uint256 public voterCount;

    uint256 public totalVotes;

    address payable public owner;

    string public electionName;
    bool public ongoingElection;
    uint256 public startDate;
    uint256 public endDate;

    // Candidate[] public candidates;

    /* <------ CONSTRUCTOR ------>*/
    constructor() public {
        owner = msg.sender;
        ongoingElection = false;
    }

    /* <------ MODIFIERS ------>*/
    modifier ownerOnly() {
        require(msg.sender == owner, "Not authorized.");
        _;
    }

    modifier checkElection() {
        _;
        bytes memory tmpElectionName = bytes(electionName);
        require(tmpElectionName.length != 0, "Please enter an election name");
        require(startDate > 0, "Please enter an end date for your election");
        require(endDate > 0, "Please enter an end date for your election");
    }

    /* <------ FUNCTIONS ------>*/
    function createElection(
        string memory _electionName,
        uint256 _startDate,
        uint256 _endDate
    ) public {
        electionName = _electionName;
        endDate = _endDate;
        startDate = _startDate;
        ongoingElection = true;
    }

    function getElection()
        public
        view
        returns (
            string memory _electionName,
            uint256 _startDate,
            uint256 _endDate,
            bool _ongoingElection
        )
    {
        return (electionName, startDate, endDate, ongoingElection);
    }

    function addCandidate(string memory _name) public ownerOnly {
        candidates[candidateCount] = Candidate(candidateCount, _name, 0);
        candidateCount++;
    }

    function getCandidate(uint256 _index)
        public
        view
        returns (string memory name, uint256 voteCount)
    {
        return (candidates[_index].name, candidates[_index].voteCount);
    }

    function getNumberCandidates() public view returns (uint256) {
        return candidateCount;
    }

    function addVoter(address _voter_address) public ownerOnly {
        require(!votersList[_voter_address].voted, "The voter already voted.");
        require(votersList[_voter_address].weight == 0, "No weight");
        voters[voterCount] = Voter({
            id_voter: voterCount,
            voter_address: _voter_address,
            authorized: true,
            weight: 1,
            vote: 0,
            voted: false,
            delegate: address(0)
        });
        votersList[_voter_address].weight = 1;
        voterCount++;
    }

    function getVoter(uint256 _index)
        public
        view
        returns (
            uint256 _id_voter,
            address voter_address,
            bool authorized,
            uint256 weight,
            uint256 vote,
            bool voted
        )
    {
        return (
            voters[_index].id_voter,
            voters[_index].voter_address,
            voters[_index].authorized,
            voters[_index].weight,
            voters[_index].vote,
            voters[_index].voted
        );
    }

    function getNumberVoters() public view returns (uint256) {
        return voterCount;
    }

    function getVotes() public view returns (uint256) {
        return totalVotes;
    }

    function toggleAuthorization(uint256 _index) public ownerOnly {
        voters[_index].authorized = true;
    }

    function vote(uint256 _voteIndex) public {
        Voter storage sender = votersList[msg.sender];
        require(!sender.voted, "Already voted.");
        /* require(voters[_voteIndex].weight > 0, "Already voted");
        require(voters[_voteIndex].authorized, "Not authorized to vote");
        require(
            ongoingElection,
            "The election has ended or has not started yet"
        );
 */
        voters[_voteIndex].vote = _voteIndex;
        voters[_voteIndex].voted = true;

        votersList[msg.sender].vote = _voteIndex;
        votersList[msg.sender].voted = true;

        candidates[_voteIndex].voteCount += votersList[msg.sender].weight;
        totalVotes += votersList[msg.sender].weight;
    }

    function delegateVote(address to) public {
        // assigns reference
        Voter storage sender = votersList[msg.sender];
        require(!sender.voted, "You already voted.");

        require(to != msg.sender, "Self-delegation is disallowed.");

        // Forward the delegation as long as
        // `to` also delegated.
        while (votersList[to].delegate != address(0)) {
            to = votersList[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }

        // Since `sender` is a reference, this
        // modifies `voters[msg.sender].voted`
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = votersList[to];
        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            candidates[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
        }
    }

    function end() public ownerOnly {
        selfdestruct(owner);
    }
}
