// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Election {
    address public admin;
    OrganizerDetails public organizer;
    InspecotrDetails public inspector;
    uint256 public candidateCount;
    uint256 voterCount;
    uint256 numOfBallots;
    mapping(uint256 => Candidate) public candidateDetails; // array of candidates
    mapping(address => Voter) public Voters; // array of eligible voters
    mapping(string => address) public blindedVotes; // array of blinded votes
    mapping(uint256 => Ballot) public Ballots; // array of Ballots
    mapping(string => bool) public usedSignatures;
    ElectionDetails public electionDetails;
    bool public start;
    bool public end;

    constructor() {
        // Initilizing default values
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        // Modifier for only admin access
        require(msg.sender == admin, "Caller is not Admin");
        _;
    }

    modifier onlyOrganizer() {
        // Modifier for only Organizer access
        require(
            msg.sender == organizer.organizerAddress,
            "Caller is not organizer"
        );
        _;
    }

    modifier onlyInspector() {
        // Modifier for only Inspector access
        require(
            msg.sender == inspector.inspectorAddress,
            "Caller is not organizer"
        );
        _;
    }

    struct OrganizerDetails {
        address organizerAddress;
        string signiturePublicKey;
    }

    struct InspecotrDetails {
        address inspectorAddress;
        string signiturePublicKey;
    }

    // Modeling a candidate
    struct Candidate {
        uint256 candidateId;
        string name;
        string slogan;
        uint256 voteCount;
    }

    // Adding new candidates
    function addCandidate(string memory _header, string memory _slogan)
        public
        onlyAdmin
    {
        Candidate memory newCandidate = Candidate({
            candidateId: candidateCount,
            name: _header,
            slogan: _slogan,
            voteCount: 0
        });
        candidateDetails[candidateCount] = newCandidate;
        candidateCount += 1;
    }

    // Modeling a Election Details
    struct ElectionDetails {
        string adminName;
        string adminEmail;
        string adminTitle;
        string electionTitle;
        string organizationTitle;
    }

    function setElectionDetails(
        string memory _adminName,
        string memory _adminEmail,
        string memory _adminTitle,
        string memory _electionTitle,
        string memory _organizationTitle,
        address _organizerAddress,
        address _inspectorAddress
    ) public onlyAdmin {
        electionDetails = ElectionDetails(
            _adminName,
            _adminEmail,
            _adminTitle,
            _electionTitle,
            _organizationTitle
        );
        organizer.organizerAddress = _organizerAddress;
        inspector.inspectorAddress = _inspectorAddress;
        start = true;
        end = false;
    }

    // Check if the signiture has been used
    function signitureIsUsed(string memory _sig) public view returns (bool) {
        return usedSignatures[_sig];
    }

    // Get Elections details
    function getAdminName() public view returns (string memory) {
        return electionDetails.adminName;
    }

    function getAdminEmail() public view returns (string memory) {
        return electionDetails.adminEmail;
    }

    function getAdminTitle() public view returns (string memory) {
        return electionDetails.adminTitle;
    }

    function getElectionTitle() public view returns (string memory) {
        return electionDetails.electionTitle;
    }

    function getOrganizationTitle() public view returns (string memory) {
        return electionDetails.organizationTitle;
    }

    // Get candidates count
    function getTotalCandidate() public view returns (uint256) {
        // Returns total number of candidates
        return candidateCount;
    }

    function setOrganizerSigniturePublicKey(string memory _publicKey)
        public
        onlyOrganizer
    {
        organizer.signiturePublicKey = _publicKey;
    }

    function setInspectorSigniturePublicKey(string memory _publicKey)
        public
        onlyInspector
    {
        inspector.signiturePublicKey = _publicKey;
    }

    // Get Organizer details
    function getOrganizerAddress() public view returns (address) {
        return organizer.organizerAddress;
    }

    // Get Inspector details
    function getInspectorAddress() public view returns (address) {
        return inspector.inspectorAddress;
    }

    function getOrganizerSigniturePublicKey()
        public
        view
        returns (string memory)
    {
        return organizer.signiturePublicKey;
    }

    function getInspectorSigniturePublicKey()
        public
        view
        returns (string memory)
    {
        return inspector.signiturePublicKey;
    }

    // Get voters count
    function getTotalVoter() public view returns (uint256) {
        // Returns total number of voters
        return voterCount;
    }

    // Get ballots count
    function getTotalBallots() public view returns (uint256) {
        // Returns total number of ballots
        return numOfBallots;
    }

    address[] public voters; // Array of address to store address of voters
    // structure that stores voter data
    struct Voter {
        address voterAddress;
        string nationalNumber;
        string phone;
        bool eligible;
        bool hasVoted;
        bool isRegistered;
        string blindedVote;
        string organizersig;
        string inspectorsig;
    }

    // Request to be added as voter
    function registerAsVoter(
        string memory _nationalNumber,
        string memory _phone
    ) public {
        Voter memory newVoter = Voter({
            voterAddress: msg.sender,
            nationalNumber: _nationalNumber,
            phone: _phone,
            eligible: false,
            hasVoted: false,
            isRegistered: true,
            blindedVote: "",
            organizersig: "",
            inspectorsig: ""
        });
        Voters[msg.sender] = newVoter;
        voters.push(msg.sender);
        voterCount += 1;
    }

    // Verify voter
    function verifyVoter(bool _verifedStatus, address voterAddress)
        public
        onlyOrganizer
    {
        Voters[voterAddress].eligible = _verifedStatus;
    }

    // blinded message is recorded in order to verify whether the Organizer has provided a correct signature on the blinded msg
    function requestBlindSig(string memory _blindedVote) public {
        require(Voters[msg.sender].eligible);
        Voters[msg.sender].hasVoted = true;
        Voters[msg.sender].blindedVote = _blindedVote;
    }

    // requested blindSig is recorded on the blockchain for auditing purposes
    function writeOrganizerSig(address _voter, string memory blindSig)
        public
        onlyOrganizer
    {
        Voters[_voter].organizersig = blindSig;
    }

    function writeInspectorSig(address _voter, string memory blindSig)
        public
        onlyInspector
    {
        Voters[_voter].inspectorsig = blindSig;
    }

    struct Ballot {
        uint256 choiceCode;
        string secretKey;
        string organizersig;
        string inspectorsig;
    }

    function vote(
        uint256 _choiceCode,
        string memory _secretKey,
        string memory _organizersig,
        string memory _inspectorsig
    ) public {
        require(start, "Election has not not been started");
        require(!end, "Election has been ended");
        Ballot memory newBallot = Ballot({
            choiceCode: _choiceCode,
            secretKey: _secretKey,
            organizersig: _organizersig,
            inspectorsig: _inspectorsig
        });
        Ballots[numOfBallots] = newBallot;
        numOfBallots++;
    }

    function validBallots(string memory _blindVote, uint256 _choiceCode)
        public
        onlyOrganizer
    {
        require(!usedSignatures[_blindVote], "This signature has been used");
        require(end, "Vote is not finished");
        usedSignatures[_blindVote] = true;
        candidateDetails[_choiceCode].voteCount += 1;
    }

    function getAdmin() public view returns (address) {
        return admin;
    }

    // Get election start and end values
    function getStart() public view returns (bool) {
        return start;
    }

    function getEnd() public view returns (bool) {
        return end;
    }

    // End election
    function endElection() public onlyAdmin {
        end = true;
        start = false;
    }
}
