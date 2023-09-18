// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.9.0;

contract Election {
    address public admin;
    uint256 candidateCount;
    uint256 voterCount;
    bool start;
    bool end;

    constructor() {
        admin = msg.sender;
        candidateCount = 0;
        voterCount = 0;
        start = false;
        end = false;
    }

    function getAdmin() public view returns (address) {
        return admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    struct Candidate {
        uint256 candidateId;
        string header;
        string slogan;
        uint256 voteCount;
        string image;
    }
    mapping(uint256 => Candidate) public candidateDetails;

    function addCandidate(
        string memory _header,
        string memory _slogan,
        string memory _image
    ) public onlyAdmin {
        Candidate memory newCandidate = Candidate({
            candidateId: candidateCount,
            header: _header,
            slogan: _slogan,
            voteCount: 0,
            image: _image
        });
        candidateDetails[candidateCount] = newCandidate;
        candidateCount += 1;
    }

    struct ElectionDetails {
        string adminName;
        string adminEmail;
        string adminTitle;
        string electionTitle;
        string organizationTitle;
    }
    ElectionDetails electionDetails;

    function setElectionDetails(
        string memory _adminName,
        string memory _adminEmail,
        string memory _adminTitle,
        string memory _electionTitle,
        string memory _organizationTitle
    )
        public
        // Only admin can add
        onlyAdmin
    {
        electionDetails = ElectionDetails(
            _adminName,
            _adminEmail,
            _adminTitle,
            _electionTitle,
            _organizationTitle
        );
        start = true;
        end = false;
    }

    function getAllCandidates() public view returns (Candidate[] memory) {
        Candidate[] memory candidates = new Candidate[](candidateCount);
        for (uint256 i = 0; i < candidateCount; i++) {
            candidates[i] = candidateDetails[i];
        }
        return candidates;
    }

    function getAdminName() public view returns (string memory) {
        return electionDetails.adminName;
    }

    function getAdminAddress() public view returns (address) {
        return admin;
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

    function getTotalCandidate() public view returns (uint256) {
        return candidateCount;
    }

    function getTotalVoter() public view returns (uint256) {
        return voterCount;
    }

    struct Voter {
        address voterAddress;
        string name;
        string email;
        string phone;
        bool isVerified;
        bool hasVoted;
        bool isRegistered;
        string govId;
        string currentImage;
        string voterIdNumber;
    }
    address[] public voters;
    mapping(address => Voter) public voterDetails;

    function registerAsVoter(
        string memory _name,
        string memory _email,
        string memory _phone,
        string memory _govId,
        string memory _currentImage,
        string memory _voterIdNumber,
        bool _isVerified
    ) public {
        Voter memory newVoter = Voter({
            voterAddress: msg.sender,
            name: _name,
            email: _email,
            phone: _phone,
            hasVoted: false,
            isVerified: _isVerified,
            isRegistered: true,
            govId: _govId,
            currentImage: _currentImage,
            voterIdNumber: _voterIdNumber
        });
        voterDetails[msg.sender] = newVoter;
        voters.push(msg.sender);
        voterCount += 1;
    }

    function verifyVoter(bool _verifedStatus, address voterAddress)
        public
        onlyAdmin
    {
        voterDetails[voterAddress].isVerified = _verifedStatus;
    }

    function rejectVoter(address voterAddress) public onlyAdmin {
        for (uint256 i = 0; i < voters.length; i++) {
            if (voters[i] == voterAddress) {
                voters[i] = voters[voters.length - 1];
                voters.pop();
                break;
            }
        }
        voterDetails[voterAddress].isRegistered = false;
        voterCount -= 1;
        delete voterDetails[voterAddress];
    }

    function vote(uint256 candidateId) public {
        require(voterDetails[msg.sender].hasVoted == false);
        require(voterDetails[msg.sender].isVerified == true);
        require(start == true);
        require(end == false);
        candidateDetails[candidateId].voteCount += 1;
        voterDetails[msg.sender].hasVoted = true;
    }

    function endElection() public onlyAdmin {
        end = true;
        start = false;
    }

    function getVoterDetails(address voterAddress)
        public
        view
        returns (Voter memory)
    {
        return voterDetails[voterAddress];
    }

    function getAllVoters() public view returns (Voter[] memory) {
        Voter[] memory votersList = new Voter[](voterCount);
        for (uint256 i = 0; i < voterCount; i++) {
            votersList[i] = voterDetails[voters[i]];
        }
        return votersList;
    }

    function getStart() public view returns (bool) {
        return start;
    }

    function getEnd() public view returns (bool) {
        return end;
    }

    function getWinner() public view returns (Candidate memory) {
        require(end == true);
        Candidate memory winner = candidateDetails[0];
        for (uint256 i = 1; i < candidateCount; i++) {
            if (candidateDetails[i].voteCount > winner.voteCount) {
                winner = candidateDetails[i];
            }
        }
        return winner;
    }
}
