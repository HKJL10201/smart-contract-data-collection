// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract Voting {
    struct Voter {
        uint aadharNumber;
        string voterName;
        uint age;
        uint stateCode;
        bool isAlive;
        uint votedTo;
    }

    struct Candidate {
        uint nominationNumber;
        string candidateName;
        string partyName;
        string partyFlag;
        uint stateCode;
    }

    struct Result {
        string candidateName;
        string partyName;
        string partyFlag;
        uint voteCount;
        uint nominationNumber;
        uint stateCode;
    }

    Candidate[] public candidate;
    mapping(uint => Candidate) candidates;
    mapping(address => Voter) voters;
    mapping(uint => uint) internal votesCount;

    address public electionChief;
    uint private votingStartTime;
    uint private votingEndTime;
    uint noOfCandidate;
    uint length = 1;

    constructor() {
        electionChief = msg.sender;
    }

    // Modifiers
    modifier isElectionChief() {
        require(msg.sender == electionChief, "Not Election Chief");
        _;
    }

    modifier isVoterEligible(uint256 _nominationNumber) {
        require(voters[msg.sender].age >= 18, "Voter is under 18");
        require(voters[msg.sender].isAlive, "Voter is Dead");
        require(voters[msg.sender].votedTo == 0, "Voter is not voted yet");
        require(
            candidates[_nominationNumber].stateCode ==
                voters[msg.sender].stateCode,
            "Voter votes where the live"
        );
        _;
    }

    modifier isVotingLinesAreOpen(uint256 _currentTime) {
        require(_currentTime >= votingStartTime, "Voting is not started");
        require(_currentTime <= votingEndTime, "Voting is ended");
        _;
    }

    // =============================================================

    // Add Voter
    function regVoter(
        uint _aadharNumber,
        string calldata _voterName,
        uint _age,
        uint _stateCode,
        bool _isAlive
    ) external {
        voters[msg.sender] = Voter(
            _aadharNumber,
            _voterName,
            _age,
            _stateCode,
            _isAlive,
            0
        );
    }

    // Vote the voter
    function vote(
        uint _nominationNumber,
        uint _currentTime
    )
        public
        isVotingLinesAreOpen(_currentTime)
        isVoterEligible(_nominationNumber)
    {
        voters[msg.sender].votedTo = _nominationNumber;

        uint _voteCount = votesCount[_nominationNumber];
        votesCount[_nominationNumber] = _voteCount + 1;
    }

    function didCurrentVoterVoted()
        public
        view
        returns (bool userVoted_, Candidate memory candidate_)
    {
        userVoted_ = (voters[msg.sender].votedTo != 0);
        if (userVoted_) candidate_ = candidates[voters[msg.sender].votedTo];
    }

    function didVoterReg() public view returns (bool userReg_) {
        userReg_ = (voters[msg.sender].aadharNumber == 0);
    }

    // =============================================================

    // Start Voting
    function startElection(
        uint256 _votingStartTime,
        uint256 _votingEndTime
    ) external isElectionChief {
        votingStartTime = _votingStartTime;
        votingEndTime = _votingEndTime;
    }

    // get Voting end time
    function getVotingEndTime() public view returns (uint256 endTime_) {
        endTime_ = votingEndTime;
    }

    // update Voting start time
    function updateVotingStartTime(
        uint256 startTime_,
        uint256 currentTime_
    ) public isElectionChief {
        require(votingStartTime > currentTime_);
        votingStartTime = startTime_;
    }

    // Extend Voting end time
    function extendVotingTime(
        uint256 endTime_,
        uint256 currentTime_
    ) public isElectionChief {
        require(votingStartTime < currentTime_);
        require(votingEndTime > currentTime_);
        votingEndTime = endTime_;
    }

    // =============================================================

    // Result
    function getResults(
        uint currentTime_
    ) public view returns (Result[] memory) {
        require(votingEndTime < currentTime_);
        Result[] memory resultsList_ = new Result[](candidate.length);
        for (uint256 i = 0; i < candidate.length; i++) {
            resultsList_[i] = Result({
                candidateName: candidate[i].candidateName,
                partyName: candidate[i].partyName,
                partyFlag: candidate[i].partyFlag,
                nominationNumber: candidate[i].nominationNumber,
                stateCode: candidate[i].stateCode,
                voteCount: votesCount[candidate[i].nominationNumber]
            });
        }
        return resultsList_;
    }

    // =============================================================

    // Add Cadidate
    function addCandidate(
        uint _nominationNumber,
        string calldata _cadidateName,
        string calldata _partyName,
        string calldata _partyFlag,
        uint _stateCode
    ) external isElectionChief {
        candidate.push(
            Candidate({
                nominationNumber: _nominationNumber,
                candidateName: _cadidateName,
                partyName: _partyName,
                partyFlag: _partyFlag,
                stateCode: _stateCode
            })
        );

        for (uint i = 0; i < candidate.length; i++) {
            candidates[candidate[i].nominationNumber] = candidate[i];
        }
    }

    // Get Cadidate
    function getCandidate() external view returns (Candidate[] memory) {
        return candidate;
    }
}
