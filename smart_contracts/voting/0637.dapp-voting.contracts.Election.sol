// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;
pragma experimental ABIEncoderV2;

contract ElectionFactory {
    Election[] public contractList;
    uint256 public contractsCount = 0;

    function addContract(string memory name, string memory description)
        public
    {
        contractsCount++;
        Election newContract = new Election(msg.sender, name, description);
        contractList.push(newContract);
    }

    function getContractList() public view returns (Election[] memory){
        return contractList;
    }
}

contract Election {
    enum State {Created, Voting, Ended}
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }
    // struct Vote {
    //     address voterAddress;
    //     uint256 choice;
    // }
    struct Voter {
        string voterName;
        address voterAddress;
        bool voted;
        uint256 choice;
    }

    // Store accounts that have voted
    mapping(uint256 => Candidate) public candidates;
    // mapping(uint256 => Vote) private votes;
    mapping(address => Voter) public voterRegister;
    uint256 public candidatesCount = 0;
    uint256 public totalVoterCount = 0;
    uint256 public totalVoteCount = 0;
    address public electionOwnerAddress;
    string public electionOfficialName;
    string public electionDescription;
    State public electionState;
    string public finalWinner;
    uint256 highest = 0;

    //constructor
    constructor(address ownerAddress, string memory name, string memory description) public {
        // addCandidate("Trump");
        //addCandidate("Bidden");
        electionOwnerAddress = ownerAddress;
        electionOfficialName = name;
        electionDescription = description;
        electionState = State.Created;
    }

    modifier onlyOwner() {
        require(msg.sender == electionOwnerAddress, "Only Owner has access");
        _;
    }
    modifier inState(State st) {
        require(electionState == st, "Validate state");
        _;
    }
    modifier onlyRegister() {
        require(
            bytes(voterRegister[msg.sender].voterName).length != 0 &&
            !voterRegister[msg.sender].voted, "Only Register has access");
        _;
    }
    function getElectionState() public view returns (State){
        return electionState;
    }

    // event
    //event votedEvent(uint256 indexed _candidateId);
    event candidateAdded(string candidateName);
    event voterRegistered(address voter);
    event voteStarted();
    event voteEnded(string finalWinner);
    event voteDone(address voter);

    function addCandidate(string memory candidateName)
        public
        inState(State.Created)
        onlyOwner
    {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(
            candidatesCount,
            candidateName,
            0
        );

        emit candidateAdded(candidateName);
    }

    function joinVote(address voterAddress, string memory voterName)
        public
        inState(State.Created)
    {
        Voter memory voter;
        voter.voterName = voterName;
        voter.voterAddress = voterAddress;
        voter.voted = false;
        voter.choice = 0;
        voterRegister[voterAddress] = voter;
        totalVoterCount++;
        emit voterRegistered(voterAddress);
    }

    function startVote() public inState(State.Created) onlyOwner {
        electionState = State.Voting;
        emit voteStarted();
    }

    function doVote(uint256 candidateId)
        public
        inState(State.Voting)
        onlyRegister
    {
        voterRegister[msg.sender].voted = true;
        voterRegister[msg.sender].choice = candidateId;
        if (candidateId > 0 && candidateId <= candidatesCount) {
            candidates[candidateId].voteCount++;
        }
        totalVoteCount++;
        emit voteDone(msg.sender);
    }

    function endVote() public inState(State.Voting) onlyOwner {
        electionState = State.Ended;
        for (uint256 i = 1; i <= candidatesCount; i++) {
            if(candidates[i].voteCount > highest){
                highest = candidates[i].voteCount;
                finalWinner = candidates[i].name;
            }
        }
        emit voteEnded(finalWinner);
    }
}
