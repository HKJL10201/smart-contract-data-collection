//pragma solidity ^0.5.11;
pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

contract VotingSystem {

    enum State {
        NOT_CREATED, //Default value & value given to unknown ballots
        CREATED, //Can add participants
        OPENED, //Can vote
        ENCLOSED //Can watch results
    }

    struct BallotExistence {
        uint id;
        bool exists;
    }

    struct Candidate {
        bytes32 name;
        uint vote;
    }

    struct Ballot {
        bytes32 name;
        State state;
        address owner;
        bytes32[] candidatesName;
        address[] voters;
    }

    bytes32[] ballots;
    mapping(bytes32 => Ballot) ballotMapping;
    mapping(bytes32 => mapping(bytes32 => Candidate)) candidatesMapping;

    modifier ballotExists(bytes32 _ballotName) {
        require(getBallotByName(_ballotName).state > State.NOT_CREATED);
        _;
    }

    modifier ownsBallot(bytes32 _ballotName) {
        require(getBallotByName(_ballotName).owner == msg.sender);
        _;
    }

    modifier isState(bytes32 _ballotName, State _state) {
        require(getBallotByName(_ballotName).state == _state);
        _;
    }

    modifier isNotAlreadyCandidate(bytes32 _ballotName, bytes32 _candidateName) {
        require(!isBallotCandidate(_ballotName, _candidateName));
        _;
    }

    modifier isCandidate(bytes32 _ballotName, bytes32 _candidateName) {
        require(isBallotCandidate(_ballotName, _candidateName));
        _;
    }

    modifier didntVote(bytes32 _ballotName) {
        Ballot memory _ballot = getBallotByName(_ballotName);
        bool hasAlreadyVoted = false;

        for(uint i = 0; i < _ballot.voters.length; i++) {
            if(_ballot.voters[i] == msg.sender) {
                hasAlreadyVoted = true;
            }
        }

        require(!hasAlreadyVoted);
        _;
    }

    function createBallot(bytes32 _ballotName) public {
        Ballot memory _newBallot = Ballot({
            name : _ballotName,
            state : State.CREATED,
            owner : msg.sender,
            candidatesName : new bytes32[](0),
            voters : new address[](0)
        });

        ballots.push(_ballotName);
        ballotMapping[_ballotName] = _newBallot;
    }

    function openBallotVotes(bytes32 _ballotName) public ballotExists(_ballotName) ownsBallot(_ballotName) isState(_ballotName, State.CREATED) {
        getStorageBallot(_ballotName).state = State.OPENED;
    }

    function closeBallotVotes(bytes32 _ballotName) public ballotExists(_ballotName) ownsBallot(_ballotName) isState(_ballotName, State.OPENED) {
        getStorageBallot(_ballotName).state = State.ENCLOSED;
    }

    function getBallotByName(bytes32 _ballotName) internal view returns (Ballot memory) {
        return ballotMapping[_ballotName];
    }

    function getBallot(bytes32 _ballotName) view public ballotExists(_ballotName) returns (Ballot memory) {
        return getBallotByName(_ballotName);
    }

    function getStorageBallot(bytes32 _ballotName) view internal ballotExists(_ballotName) returns (Ballot storage) {
        return ballotMapping[_ballotName];
    }

    function isCreated(bytes32 _ballotName) view public ballotExists(_ballotName) returns (bool) {
        return getBallotByName(_ballotName).state == State.CREATED;
    }

    function isOpened(bytes32 _ballotName) view public ballotExists(_ballotName) returns (bool) {
        return getBallotByName(_ballotName).state == State.OPENED;
    }

    function isEnclosed(bytes32 _ballotName) view public ballotExists(_ballotName) returns (bool) {
        return getBallotByName(_ballotName).state == State.ENCLOSED;
    }

    function isBallotCandidate(bytes32 _ballotName, bytes32 _candidateName) internal view returns (bool) {
        Ballot memory _ballot = getBallotByName(_ballotName);
        bool candidateExists = false;
        for(uint i = 0; i < _ballot.candidatesName.length; i++) {
            if(_ballot.candidatesName[i] == _candidateName) {
                candidateExists = true;
            }
        }

        return candidateExists;
    }

    function addCandidate(bytes32 _ballotName, bytes32 _candidateName) public ballotExists(_ballotName) isNotAlreadyCandidate(_ballotName, _candidateName) isState(_ballotName, State.CREATED) {
        Ballot storage _ballot = getStorageBallot(_ballotName);
        _ballot.candidatesName.push(_candidateName);
        candidatesMapping[_ballotName][_candidateName].name = _candidateName;
        candidatesMapping[_ballotName][_candidateName].vote = 0;
    }

    function getCandidatesResult(bytes32 _ballotName) public view ballotExists(_ballotName) returns (Candidate[] memory) {
        Ballot memory _ballot = getBallotByName(_ballotName);
        Candidate[] memory _candidates = new Candidate[](_ballot.candidatesName.length);
        for(uint i = 0; i < _ballot.candidatesName.length; i++) {
            _candidates[i] = candidatesMapping[_ballotName][_ballot.candidatesName[i]];
        }

        return _candidates;
    }

    function voteForCandidate(bytes32 _ballotName, bytes32 _candidateName) public ballotExists(_ballotName) isCandidate(_ballotName, _candidateName) isState(_ballotName, State.OPENED) didntVote(_ballotName) {
        candidatesMapping[_ballotName][_candidateName].vote += 1;
        getStorageBallot(_ballotName).voters.push(msg.sender);
    }
}
