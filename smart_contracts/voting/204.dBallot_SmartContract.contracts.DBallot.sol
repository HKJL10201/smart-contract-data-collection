// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/* Errors */
error DBallot__NotOwner();
error DBallot__VoterHasVoted();
error DBallot__InvalidCandidate();
error DBallot__VotingPeriodHasEnded();
error DBallot__NotElectionYear(uint256 _nextElectionYear);
error DBallot__ElectionHasStarted();
error DBallot__ElectionHasTakenPlace();

/**
 * @title DBallot
 * @author Abdulbasit Akingbade
 * @dev A simple voting contract
 * @dev The contract owner declares the start date of the election for the current year
 * @dev The contract owner adds candidates for the current election year
 * @dev Voters can only vote during the voting period
 */
contract DBallot {
    address private immutable i_owner;
    uint256 private s_nextElectionYear; // TODO: update s_nextElectionYear after election
    uint256 private s_tenureInYears;
    // uint256 private s_electionStartDate;
    mapping(uint256 => uint256) private s_electionStartDate;
    // uint256 private s_totalCandidatesCount;
    // mapping(uint256 => uint256) private s_totalCandidatesCount;
    // uint256 private s_totalVotes;
    mapping(uint256 => uint256) private s_totalVotes;

    uint256 private s_electionDurationInHours;

    // mapping(uint256 => Candidate) private s_candidates;
    mapping(uint256 => Candidate[]) private s_candidates;
    // mapping(address => Voter) public s_voters;
    mapping(uint256 => mapping(address => Voter)) private s_voters;

    struct Candidate {
        uint256 id;
        string name;
        string description;
        string logoUrl;
        uint256 voteCount;
    }

    struct Voter {
        bool hasVoted;
        uint256 votedCandidateId /**candidateId of who they voted for */;
    }

    /* Events */
    event CandidateAdded(
        uint256 _id,
        string _name,
        string _description,
        string _logoUrl,
        uint256 _year
    );
    event VoteCasted(
        address indexed _voter,
        uint256 indexed _year,
        uint256 _candidateId
    );
    event ElectionStarted(uint256 indexed _year, uint256 _startDate);

    /* Modifiers */
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert DBallot__NotOwner();
        _;
    }

    modifier validElectionYear() {
        if (getCurrentYear() < s_nextElectionYear)
            revert DBallot__NotElectionYear(s_nextElectionYear);
        _;
    }

    modifier onlyDuringVotingPeriod() {
        if (
            ((getCurrentYear() - s_nextElectionYear) % s_tenureInYears) != 0 ||
            //(s_electionStartDate[getCurrentYear()] != 0 ||
            block.timestamp < s_electionStartDate[getCurrentYear()] ||
            block.timestamp >
            s_electionStartDate[getCurrentYear()] +
                (s_electionDurationInHours * 3600)
        ) revert DBallot__VotingPeriodHasEnded();
        _;
    }

    /**
     * @param _tenureInYears the number of years before the next election takes place
     */
    constructor(uint256 _tenureInYears) {
        i_owner = msg.sender;
        s_tenureInYears = _tenureInYears;
        s_nextElectionYear = getCurrentYear();
    }

    /**
     * @dev Declares the start date of the election for the current year
     * @dev Only the owner can call this function
     * @dev The election can only be declared during an election year i.e past election year + tenure
     * @param _electionDurationInHours the duration the
     */
    function startElection(
        uint256 _electionDurationInHours
    ) public onlyOwner validElectionYear {
        uint256 currentYear = getCurrentYear();
        if (s_electionStartDate[currentYear] != 0)
            revert DBallot__ElectionHasTakenPlace();
        uint256 time = block.timestamp;
        s_electionStartDate[currentYear] = time;
        s_electionDurationInHours = _electionDurationInHours;
        //s_nextElectionYear = currentYear + s_tenureInYears;

        emit ElectionStarted(currentYear, time);
    }

    // add candidates
    /**
     * @param _name the name of the party
     * @param _description the description of the party
     * @param _logoUrl the url of the party logo
     * @dev Only the owner can call this function
     * @dev Candidates can only be added during an election year
     */
    function addCandidate(
        string memory _name,
        string memory _description,
        string memory _logoUrl
    ) public onlyOwner validElectionYear {
        if (
            s_electionStartDate[getCurrentYear()] != 0 &&
            block.timestamp > s_electionStartDate[getCurrentYear()]
        ) revert DBallot__ElectionHasStarted();
        require(bytes(_name).length > 0, "DBallot: party name cannot be empty");
        // Check if candidate with the same party name already exists
        Candidate[] memory candidates = s_candidates[getCurrentYear()];
        for (uint i = 0; i < candidates.length; i++) {
            if (
                keccak256(bytes(candidates[i].name)) == keccak256(bytes(_name))
            ) {
                revert("Candidate with same party name already exists");
            }
        }
        Candidate memory candidate = Candidate({
            id: getTotalCandidatesCount(getCurrentYear()),
            name: _name,
            description: _description,
            logoUrl: _logoUrl,
            voteCount: 0
        });
        s_candidates[getCurrentYear()].push(candidate);

        emit CandidateAdded(
            candidate.id,
            candidate.name,
            candidate.description,
            candidate.logoUrl,
            getCurrentYear()
        );
    }

    // vote
    /**
     * @param _candidateId the id of the candidate
     * @dev Votes can only be casted during the voting period
     * @dev i.e during an election, after the start date and before the voting period ends
     */
    function castVote(uint256 _candidateId) public onlyDuringVotingPeriod {
        // require that they haven't voted before
        if (s_voters[getCurrentYear()][msg.sender].hasVoted)
            revert DBallot__VoterHasVoted();
        // require a valid candidate
        if (_candidateId >= getTotalCandidatesCount(getCurrentYear()))
            revert DBallot__InvalidCandidate();
        // record that voter has voted
        s_voters[getCurrentYear()][msg.sender] = Voter({
            hasVoted: true,
            votedCandidateId: _candidateId
        });
        // update candidate vote Count
        s_candidates[getCurrentYear()][_candidateId].voteCount++;
        s_totalVotes[getCurrentYear()]++;

        emit VoteCasted(msg.sender, _candidateId, getCurrentYear());
    }

    // get results
    /*function getResults(
        uint256 _electionYear
    ) public view returns (Candidate[] memory) {
        Candidate[] memory results = new Candidate[](
            getTotalCandidatesCount(_electionYear)
        );
        for (uint256 i = 0; i < getTotalCandidatesCount(_electionYear); i++) {
            results[i].id = s_candidates[_electionYear][i].id;
            results[i].name = s_candidates[_electionYear][i].name;
            results[i].voteCount = s_candidates[_electionYear][i].voteCount;
        }
        return results;
    }*/

    /* Setters */
    // function setNextElectionDate(uint256) public view returns (uint256) {
    //     return s_nextElectionYear;
    // }

    /* View / Pure functions */

    /**
     * @notice assumes that a year is exactly 365 days long,
     *         which is not strictly true due to leap years
     * @return the current year
     */
    function getCurrentYear() internal view returns (uint256) {
        uint256 yearsSince1970 = block.timestamp / 365 days;
        return 1970 + yearsSince1970;
    }

    /**
     * @return the next election year
     */
    function getNextElectionYear() public view returns (uint256) {
        return s_nextElectionYear;
    }

    /**
     * @dev gets the total number of candidates for the given election year
     * @param _electionYear the year of the election
     */
    function getTotalCandidatesCount(
        uint256 _electionYear
    ) public view returns (uint256) {
        return s_candidates[_electionYear].length;
    }

    /**
     * @dev gets the total number of votes casted for the given election year
     * @param _electionYear the year of the election
     */
    function getTotalVotes(
        uint256 _electionYear
    ) public view returns (uint256) {
        return s_totalVotes[_electionYear];
    }

    /**
     * @param _electionYear the year of the election
     * @return the start date of the election for the given year
     */
    function getElectionStartDate(
        uint256 _electionYear
    ) public view returns (uint256) {
        return s_electionStartDate[_electionYear];
    }

    /**
     * @param _electionYear the year of the election
     * @param _voterAddress the address of the voter
     * @return the voter details
     */
    function getVoter(
        uint256 _electionYear,
        address _voterAddress
    ) public view returns (Voter memory) {
        Voter memory voter = s_voters[_electionYear][_voterAddress];
        return voter;
    }

    function getElectionWinner(
        uint256 _electionYear
    ) public view returns (Candidate memory) {
        Candidate[] memory candidates = s_candidates[_electionYear];
        Candidate memory winner = candidates[0];
        for (uint256 i = 1; i < getTotalCandidatesCount(_electionYear); i++) {
            if (candidates[i].voteCount > winner.voteCount) {
                winner = candidates[i];
            }
        }
        return winner;
    }

    /**
     * @param _electionYear the year of the election
     * @param _candidateId the id of the candidate
     * @return the candidate details
     */
    function getCandidate(
        uint256 _electionYear,
        uint256 _candidateId
    ) public view returns (Candidate memory) {
        require(
            _candidateId < getTotalCandidatesCount(_electionYear),
            "Invalid candidate ID"
        );
        Candidate memory candidate = s_candidates[_electionYear][_candidateId];
        return candidate;
    }
}
