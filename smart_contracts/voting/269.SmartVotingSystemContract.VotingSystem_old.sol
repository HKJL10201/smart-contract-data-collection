pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

contract VotingSystem {

    enum Distinction { Bad, Mediocre, Inadequate, Passable, Good, VeryGood, Excellent }
    enum State {
        CREATED, //Can add participants
        OPENED, //Can vote
        CLOSED //Can watch results
    }

    struct Ballot {
        string name; // Unique value
        Candidate[] candidates;
        address owner;
        address[] voters;
        State state;
        bool exists;
    }

    struct Vote {
        string candidate;
        Distinction distinction;
    }

    struct Candidate {
        string name;
        uint[] votes;
    }

    Ballot[] ballots;
    mapping(string => uint) ballotMapping;

    modifier ballotExists(string memory _ballotName) {
        require(getBallotByName(_ballotName).exists);
        _;
    }

    modifier ballotDoesntExists(string memory _ballotName) {
        require(!getBallotByName(_ballotName).exists);
        _;
    }

    modifier ownsBallot(string memory _ballotName) {
        require(getBallotByName(_ballotName).owner == msg.sender);
        _;
    }

    modifier isState(string memory _ballotName, State _state) {
        require(getBallotByName(_ballotName).state == _state);
        _;
    }

    modifier didntVote(string memory _ballotName) {
        bool voted = false;

        Ballot memory ballot = getBallotByName(_ballotName);

        for(uint i = 0; i < ballot.voters.length; i++) {
            if(ballot.voters[i] == msg.sender) {
                voted = true;
            }
        }

        require(voted == false);
        _;
    }

    function createBallot(string memory _ballotName) public ballotDoesntExists(_ballotName) {
//        Ballot memory newBallot = ballots[_ballotName];
//
//        newBallot.name = _ballotName;
//        newBallot.candidates = new Candidate[](0);
//        newBallot.owner = msg.sender;
//        newBallot.voters = new address[](0);
//        newBallot.state = State.CREATED;
//        newBallot.exists = true;



        /*
        1. Creates an array with every ballots and a mapping with name => id in the array
            (cf. https://medium.com/loom-network/ethereum-solidity-memory-vs-storage-how-to-initialize-an-array-inside-a-struct-184baf6aa2eb)
        2. Use only the array and returns the ID in the createBallot function ?
            (cf. CrowdFunding.newCampaign();)
        */

//        Ballot memory _newBallot = Ballot({
//            name: _ballotName,
//            candidates: new Candidate[](0),
//            owner: msg.sender,
//            voters: new address[](0),
//            state: State.CREATED,
//            exists: true
//        });
//
//        ballotMapping[_ballotName] = ballots.push(_newBallot);
    }

//    function openBallotVotes(string memory _ballotName) public ballotExists(_ballotName) ownsBallot(_ballotName) isState(_ballotName, State.CREATED) {
//        getBallotByName(_ballotName).state = State.OPENED;
//    }

//    function closeBallotVotes(string memory _ballotName) public ballotExists(_ballotName) ownsBallot(_ballotName) isState(_ballotName, State.OPENED) {
//        getBallotByName(_ballotName).state = State.CLOSED;
//    }

//    function addCandidate(string memory _ballotName, string[] memory _candidatesName) public ballotExists(_ballotName) ownsBallot(_ballotName) isState(_ballotName, State.CREATED) {
//        uint _ballotId = ballotMapping[_ballotName];
//
//        for(uint i = 0; i < _candidatesName.length; i++) {
//            ballots[_ballotId].candidates.length++;
//            ballots[_ballotId].candidates[ballots[_ballotId].candidates.length - 1].name = _candidatesName[i];
//        }
//    }

//    function vote(string memory _ballotName, Vote[] memory _votes) public ballotExists(_ballotName) isState(_ballotName, State.OPENED) didntVote(_ballotName) {
//        uint _ballotId = ballotMapping[_ballotName];
//
//        for(uint i = 0; i < _votes.length; i++) {
//            uint candidatePosition = getCandidatePosition(_ballotName, _votes[i].candidate);
//            if(candidatePosition == uint(-1)) {
//                revert("Candidate does not exists.");
//            }
//
//            ballots[_ballotId].candidates[candidatePosition].votes[uint(_votes[i].distinction)]++;
//        }
//
//        ballots[_ballotId].voters.push(msg.sender);
//    }

//    function getResult(string memory _ballotName) public view ballotExists(_ballotName) returns (Candidate[] memory) {
//        return getBallotByName(_ballotName).candidates;
//    }



//    function getCandidatePosition(string memory _ballotName, string memory candidateName) view internal ballotExists(_ballotName) returns (uint) {
//        Ballot memory ballot = getBallotByName(_ballotName);
//        for(uint i = 0; i < ballot.candidates.length; i++) {
//            if(stringAreEquals(ballot.candidates[i].name, candidateName)) {
//                return i;
//            }
//        }
//
//        return uint(-1);
//    }

    function stringAreEquals(string memory a, string memory b) pure internal returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }





//    function watchBallots() public view returns (Ballot[] memory) {
//        return ballots;
//    }

    function watchBallot(string memory _ballotName) public view returns (Ballot memory) {
        return getBallotByName(_ballotName);
    }

//    function getCandidates(string memory _ballotName) public view returns (string[] memory) {
//        Ballot memory ballot = getBallotByName(_ballotName);
//
//        uint candidatesLength = ballot.candidates.length;
//        string[] memory candidatesName = new string[](candidatesLength);
//        for(uint index = 0; index < candidatesLength; index++) {
//            candidatesName[index] = ballot.candidates[index].name;
//        }
//
//        return candidatesName;
//    }


    function getBallotByName(string memory _ballotName) internal view returns (Ballot memory) {
        uint _ballotId = ballotMapping[_ballotName];
        return ballots[_ballotId];
    }
}