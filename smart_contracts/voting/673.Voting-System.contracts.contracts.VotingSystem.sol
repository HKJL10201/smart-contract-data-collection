// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract votingSystem {

    address payable administrator;
    // mapping (address => bool) registeredList;
    Election electionInfo;
    // mapping (address => Status) voters;
    mapping (address => Voter) voters;
    mapping (address => uint) voteCount;
    // mapping (int8 => Candidate) candidates;
    mapping (address => Candidate) candidates;
    address[] candidateAdd;
    address[] voterAdd;

    // uint8 candidateNumber;
    
    enum Level {local, state, country}
    enum ElectionType {regular, filling}
    enum Status {registered, approved, voted}
    enum ElectionStatus {preparation, ongoing, finished}
     //false once voted or if changed the address

    uint totalVote;

    struct Candidate {
        string name;
        string party;
        uint8 age;
        uint aadharNumber;
        Status candidateStatus;
        // address candidateAddress;
    }

    // RETHINK: need to have voter's information in the blockchain or not
    struct Voter {
        string name;
        uint8 age;
        uint aadharNumber;
        uint phoneNumber;
        Status currStatus;
    }

    struct Election {
        string name;
        Level level;
        ElectionType electionType;
        ElectionStatus status;
    }

    modifier onlyAdmin {
        require(administrator == msg.sender, "Only administrators have the access to this action");
        _;
    }

    modifier isOngoing {
        require(electionInfo.status == ElectionStatus(1), "Election is in progress.");
        _;
    }

    modifier isReady {
        require(electionInfo.status == ElectionStatus(0), "Election is still about to start.");
        _;
    }

// take the election info during construction of the contract
    constructor(string memory _name, uint8 _level, uint8 _electionType, address payable _address) {
        administrator = _address;
        require(_level <= 2, "Out of bound");
        require(_electionType <= 1, "Out of bound");
        electionInfo = Election(_name, Level(_level), ElectionType(_electionType), ElectionStatus(0));
    }

    function startElection() public onlyAdmin {
        require(electionInfo.status == ElectionStatus(0));
        electionInfo.status = ElectionStatus(1);
    }

    function endElection() public onlyAdmin {
        require(electionInfo.status == ElectionStatus(0));
        electionInfo.status = ElectionStatus(1);
    }

    function vote(address _address) public isOngoing {
        require(voters[msg.sender].currStatus == Status.approved, "Either you not registered or already voted");
        voteCount[_address]++;
        totalVote++;
        voters[msg.sender].currStatus = Status.voted;
    }

    // can a person register more than once with this function ?
    function registerVoter(string memory _name, uint8 _age, uint _aadharNumber, uint _phone) public isReady {
        Voter memory newVoter = Voter(_name, _age, _aadharNumber, _phone, Status.registered);
        voterAdd.push(msg.sender);
        voters[msg.sender] = newVoter;
    }

    //register candidate
    function registerCandidate(string memory _name, string memory _party, uint8 _age, uint _aadharNumber) public isReady payable {
        require(msg.value == 1 ether, "Amount should be exactly equal to 1 ETHER");
        Candidate memory newCandidate = Candidate(_name, _party, _age, _aadharNumber, Status.registered);
        candidateAdd.push(msg.sender);
        candidates[msg.sender] = newCandidate;
        administrator.transfer(msg.value);
    } 

    function approveCandidate(address _address) public onlyAdmin isReady {
        // after approving candidate add them in a seperate place with an ID
        require(candidates[_address].candidateStatus == Status.registered,"Candidate not registered");
        require(candidates[_address].age >= 30, "Candidate is not eligible");
        candidates[_address].candidateStatus = Status.approved;
    }

    // should I also add register candidate and then approveCandidate or just addCandidate
    // ----> Need to remove this probably
    // function addCandidate(string memory _name, string memory _party, uint8 _age, address _address) public onlyAdmin{
    //     // Candidate storage newCandidate = candidates[candidateNumber];
    //     Candidate storage newCandidate = candidates[_address];
    //     newCandidate.name = _name;
    //     newCandidate.party = _party;
    //     newCandidate.age = _age;
    //     // newCandidate.candidateAddress = _address;
    //     newCandidate.candidateStatus = Status.approved;
    // }

    function approveVoter(address votersAddress) public onlyAdmin isReady {
        require(voters[votersAddress].currStatus == Status.registered, "Either the voter is not registered or already approved");
        require(voters[votersAddress].age >= 18, "Not an eligible voter");
        voters[votersAddress].currStatus = Status.approved;
    }

    function getPersonalInfo() public view returns(string memory, uint8, uint, uint, Status) {
        Voter memory prsInfo = voters[msg.sender];
        return(prsInfo.name, prsInfo.age, prsInfo.aadharNumber, prsInfo.phoneNumber, prsInfo.currStatus);
    }

    function getElectionInfo() public view returns(string memory, Level, ElectionType, ElectionStatus) {
        return(electionInfo.name, electionInfo.level, electionInfo.electionType, electionInfo.status);
    }

    function getCandidates() public view returns(address[] memory) {
        return(candidateAdd);
    }

    function getCandidateInfo(address _address) public view returns(string memory, string memory, uint8, uint, Status) {
        Candidate memory candidate = candidates[_address];
        return(candidate.name, candidate.party, candidate.age, candidate.aadharNumber, candidate.candidateStatus);
    }

    function getVoters() public view returns (address[] memory) {
        return (voterAdd);
    }

    function getVoterInfo(address _address) public view returns(string memory, uint8, uint, uint, Status) {
        Voter memory voter = voters[_address];
        return(voter.name, voter.age, voter.aadharNumber, voter.phoneNumber, voter.currStatus);
    }

    function getResult(address _address) public view returns(uint, uint) {
        return (voteCount[_address], totalVote);
    }
    //create show functions that can give the data about the user, candidate, election
}
