// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Election {
    struct ElectionInfo {
        string electionName;
        string organizationName;
        bool isInitialized; // Ensure the election to be initialized only once
    }

    struct ElectionStatus {
        uint256 startTime; // 0 by default (Start right after a election is created)
        uint256 endTime; // 0 by default (Admin can manually end the election)
        bool isStarted;
        bool isTerminated; // true will means an unrevertable termination
    }

    struct Candidate {
        uint256 id;
        string candidateName;
        string slogan;
        uint256 voteCount;
    }

    struct Voter {
        address voterAddress;
        bool isRegistered;
        bool isVerified;
        bool hasVoted;
    }

    event ElectionCreated(
        string electionName,
        string organizationName,
        bool isInitialized
    );

    event CandidateAdded(
        uint256 id,
        string candidateName,
        string slogan,
        uint256 voteCount
    );

    event ElectionStarted(
        uint256 startTime,
        uint256 endTime,
        bool isStarted,
        bool isTerminated
    );

    event VoterRegistered(
        address voterAddress,
        bool isRegistered,
        bool isVerified,
        bool hasVoted
    );

    event VoterVerified(address voterAddress);

    event VoterVoted(address voterAddress);

    event ElectionEnded();

    // Here are all the variables
    bytes32 public immutable root; // Merkle root generated from a set of eligible addresses
    address admin; // The creator of this election
    ElectionInfo electionInfo;
    ElectionStatus electionStatus;
    mapping(uint256 => Candidate) candidateSet;
    uint256 candidateNumber;
    mapping(address => Voter) voterSet; // (OLD - No longer required with merkle root)
    mapping(address => bool) public voted; // Mapping of voters who already voted
    address[] registeredVoters; // Array of address to store address of voters (OLD - No longer required with merkle root)

    constructor(bytes32 _root) {
        root = _root;
        admin = msg.sender;
        electionInfo = ElectionInfo({
            electionName: "",
            organizationName: "",
            isInitialized: false
        });
        electionStatus = ElectionStatus({
            startTime: 0,
            endTime: 0,
            isStarted: false,
            isTerminated: false
        });
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function!");
        _;
    }

    modifier uninitialized() {
        require(
            !electionInfo.isInitialized,
            "Election is already initialized!"
        );
        _;
    }

    modifier notStarted() {
        require(!electionStatus.isStarted, "Election is already started!");
        _;
    }

    modifier notRegistered(address _voterAddress) {
        require(
            voterSet[_voterAddress].isRegistered == false,
            "Voter is already registered!"
        );
        _;
    }

    modifier stillAvailable() {
        if (electionStatus.startTime != 0) {
            require(
                block.timestamp > electionStatus.startTime,
                "Election is not available yet!"
            );
        }
        if (
            electionStatus.endTime != 0 &&
            block.timestamp > electionStatus.endTime
        ) {
            electionStatus.isTerminated = true;
        }
        require(!electionStatus.isTerminated, "Election is already ended!");
        _;
    }

    modifier canVote(bytes32[] calldata _proof) {
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_proof, root, _leaf),
            "Incorrect merkle proof!"
        );
        require(!voted[msg.sender], "Already voted!");
        voted[msg.sender] = true;
        require(electionStatus.isStarted, "Election is not started!");
        require(voterSet[msg.sender].hasVoted == false, "Already voted!");
        require(
            voterSet[msg.sender].isVerified == true,
            "Voter is not verified!"
        );
        _;
    }

    function getAdmin() public view returns (address) {
        return admin;
    }

    function setAdmin(address _admin) public onlyAdmin stillAvailable {
        require(_admin == address(0x0), "Admin cannot be set to 0x0!");
        admin = _admin;
    }

    // Initialize and start the election
    function initElection(
        string memory _electionName,
        string memory _organizationName
    ) public onlyAdmin uninitialized {
        electionInfo = ElectionInfo({
            electionName: _electionName,
            organizationName: _organizationName,
            isInitialized: true
        });
        emit ElectionCreated(_electionName, _organizationName, true);
    }

    // Add new candidates
    function addCandidate(string memory _candidateName, string memory _slogan)
        public
        onlyAdmin
        notStarted
    {
        Candidate memory newCandidate = Candidate({
            id: candidateNumber,
            candidateName: _candidateName,
            slogan: _slogan,
            voteCount: 0
        });
        candidateSet[candidateNumber] = newCandidate;
        emit CandidateAdded(candidateNumber, _candidateName, _slogan, 0);
        candidateNumber += 1;
    }

    // Start election
    function startElection(uint256 _startTime, uint256 _endTime)
        public
        onlyAdmin
        notStarted
    {
        electionStatus = ElectionStatus({
            startTime: _startTime,
            endTime: _endTime,
            isStarted: true,
            isTerminated: false
        });
        emit ElectionStarted(_startTime, _endTime, true, false);
    }

    // Start election
    function startElectionWithoutDeadline() public onlyAdmin notStarted {
        electionStatus = ElectionStatus({
            startTime: 0,
            endTime: 0,
            isStarted: true,
            isTerminated: false
        });
        emit ElectionStarted(0, 0, true, false);
    }

    function getElectionInfo()
        public
        view
        returns (
            string memory,
            string memory,
            bool
        )
    {
        return (
            electionInfo.electionName,
            electionInfo.organizationName,
            electionInfo.isInitialized
        );
    }

    function getElectionStatus()
        public
        view
        returns (
            uint256,
            uint256,
            bool,
            bool
        )
    {
        return (
            electionStatus.startTime,
            electionStatus.endTime,
            electionStatus.isStarted,
            electionStatus.isTerminated
        );
    }

    function getAllCandidates()
        public
        view
        returns (
            uint256[] memory,
            string[] memory,
            string[] memory,
            uint256[] memory
        )
    {
        uint256[] memory id = new uint256[](candidateNumber);
        string[] memory candidateName = new string[](candidateNumber);
        string[] memory slogan = new string[](candidateNumber);
        uint256[] memory voteCount = new uint256[](candidateNumber);
        for (uint256 i = 0; i < candidateNumber; i++) {
            id[i] = candidateSet[i].id;
            candidateName[i] = candidateSet[i].candidateName;
            slogan[i] = candidateSet[i].slogan;
            voteCount[i] = candidateSet[i].voteCount;
        }
        return (id, candidateName, slogan, voteCount);
    }

    // Register a voter
    function registerVoter() public stillAvailable notRegistered(msg.sender) {
        Voter memory newVoter = Voter({
            voterAddress: msg.sender,
            isRegistered: true,
            isVerified: false,
            hasVoted: false
        });
        voterSet[msg.sender] = newVoter;
        registeredVoters.push(msg.sender);
        emit VoterRegistered(msg.sender, true, false, false);
    }

    function getIsRegistered() public view returns (bool) {
        return voterSet[msg.sender].isRegistered;
    }

    function getAllVoters()
        public
        view
        returns (
            address[] memory,
            bool[] memory,
            bool[] memory,
            bool[] memory
        )
    {
        address[] memory voterAddress = new address[](registeredVoters.length);
        bool[] memory isVerified = new bool[](registeredVoters.length);
        bool[] memory isRegistered = new bool[](registeredVoters.length);
        bool[] memory hasVoted = new bool[](registeredVoters.length);
        for (uint256 i = 0; i < registeredVoters.length; i++) {
            address add = registeredVoters[i];
            voterAddress[i] = voterSet[add].voterAddress;
            isRegistered[i] = voterSet[add].isRegistered;
            isVerified[i] = voterSet[add].isVerified;
            hasVoted[i] = voterSet[add].hasVoted;
        }
        return (voterAddress, isRegistered, isVerified, hasVoted);
    }

    // Verify a voter
    function verifyVoter(address voterAddress) public onlyAdmin stillAvailable {
        voterSet[voterAddress].isVerified = true;
        emit VoterVerified(voterAddress);
    }

    // Vote
    function vote(uint256 id, bytes32[] calldata _proof)
        public
        stillAvailable
        canVote(_proof)
    {
        candidateSet[id].voteCount += 1;
        voterSet[msg.sender].hasVoted = true;
        emit VoterVoted(msg.sender);
    }

    // End election
    function endElection() public onlyAdmin stillAvailable {
        electionStatus.isTerminated = true;
        emit ElectionEnded();
    }
}
