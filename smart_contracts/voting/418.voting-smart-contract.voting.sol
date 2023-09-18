// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Voting {
    mapping(address => Voter) voters;
    Voter[] votersArr;
    address private owner;
    bool votingStatus;
    Candidates candidatesContract;

    struct Voter {
        string fullname;
        string identicalNumber;
        uint8 age;
        bool hasVote;
    }

    event ChangeVotingStatus(bool votingStatus);
    event SCFeedback(bool, bytes);

    modifier isOwner() {
        require(msg.sender == owner, "You must be the Owner");
        _;
    }

    modifier is18(uint8 _age) {
        require(_age > 17, "The minimum age for voting is 18");
        _;
    }

    modifier isZeroBalance() {
        require(
            msg.sender.balance > 100000000000000,
            "You must have more than 0.0001 ether"
        );
        _;
    }

    modifier isVoterNew(address _address) {
        require(
            voters[_address].age == 0, //using age because i have only age validator
            "You have already registered as a voter"
        );
        _;
    }

    modifier isVoterRegistered(address _address) {
        require(
            voters[_address].age > 0, //using age because i have only age validator
            "First you have to registered as a voter"
        );
        _;
    }

    modifier hasVote(address voterAdd) {
        require(voters[voterAdd].hasVote, "You don't have a vote");
        _;
    }

    modifier isVotingTrue() {
        require(votingStatus, "Voting is off");
        _;
    }

    modifier isVotingFalse() {
        require(!votingStatus, "Voting is on");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addCandidatesContract(
        Candidates _candidatesContract
    ) public isOwner {
        candidatesContract = _candidatesContract;
    }

    function viewAllVoters() public view returns (uint, Voter[] memory) {
        return (votersArr.length, votersArr);
    }

    function checkVotingProcess() public view returns (bool) {
        return votingStatus;
    }

    function startVotingProcess() external isOwner isVotingFalse {
        votingStatus = true;
        emit ChangeVotingStatus(votingStatus);
    }

    function stopVotingProcess() external isOwner isVotingTrue {
        votingStatus = false;
        emit ChangeVotingStatus(votingStatus);
    }

    function vote(
        uint8 _participantNumber
    ) external isVoterRegistered(msg.sender) isVotingTrue hasVote(msg.sender) {
        voters[msg.sender].hasVote = false; //don't update hasvote in array to avoid high gas
        candidatesContract.updateCandidateVote(_participantNumber);
    }

    function registerAsVoter(
        string calldata _fullname,
        string calldata _identicalNumber,
        uint8 _age
    ) external isVoterNew(msg.sender) is18(_age) isZeroBalance {
        voters[msg.sender] = Voter(_fullname, _identicalNumber, _age, true);
        votersArr.push(Voter(_fullname, _identicalNumber, _age, true));
    }

    function projectSubmitted(
        string memory _codeFileHash,
        string memory _topicName,
        string memory _authorName,
        address _sendHashTo
    ) external payable isOwner returns (bool, bytes memory) {
        (bool _success, bytes memory responseData) = payable(
            address(_sendHashTo)
        ).call{value: msg.value}(
            abi.encodeWithSignature(
                "receiveProjectData(string,string,string)",
                _codeFileHash,
                _topicName,
                _authorName
            )
        );
        emit SCFeedback(_success, responseData);
        return (_success, responseData);
    }

    function checkProjectSubmit(
        address _sendHashTo
    ) external isOwner returns (bool success) {
        (bool _success, bytes memory responseData) = address(_sendHashTo).call(
            abi.encodeWithSignature("isProjectReceived()")
        );
        emit SCFeedback(_success, responseData);
        return (_success);
    }

    function donateToContractOwner() public payable {
        payable(owner).transfer(msg.value);
    }

    receive() external payable {
        payable(owner).transfer(msg.value); //why not
    }

    fallback() external payable {}
}

contract Candidates {
    mapping(uint8 => Candidate) candidates;
    Candidate[] candidatesArr;
    uint8 maxCandidates = 10;
    address owner;
    address votingAddress;

    struct Candidate {
        uint8 participantNumber;
        uint256 identicalNumber;
        string fullname;
        string slogan;
        uint256 votes;
    }

    event CalculateVotes(Candidate[]);
    event WinnerCandidate(Candidate);

    modifier checkMaxCandidates() {
        require(candidatesArr.length < maxCandidates, "Too many candidates");
        _;
    }

    modifier isOwner() {
        require(msg.sender == owner, "You must be the Owner");
        _;
    }

    modifier isSCSafe() {
        require(
            msg.sender == votingAddress,
            "You don't have permission to vote"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addVotingContract(address _votingAddress) public isOwner {
        votingAddress = _votingAddress;
    }

    function showAllCanidates() public view returns (uint, Candidate[] memory) {
        return (candidatesArr.length, candidatesArr);
    }

    function updateCandidateVote(uint8 _participantNumber) external isSCSafe {
        candidates[_participantNumber].votes++;
    }

    function addCandidate(
        uint8 _participantNumber,
        uint256 _identicalNumber,
        string calldata _fullname,
        string calldata _slogan
    ) external isOwner checkMaxCandidates {
        candidatesArr.push(
            Candidate(
                _participantNumber,
                _identicalNumber,
                _fullname,
                _slogan,
                0
            )
        );
        candidates[_participantNumber] = Candidate(
            _participantNumber,
            _identicalNumber,
            _fullname,
            _slogan,
            0
        );
    }

    function deleteCandidate(uint8 index) external isOwner {
        for (uint i = index; i < candidatesArr.length - 1; i++) {
            candidatesArr[i] = candidatesArr[i + 1];
        }
        candidatesArr.pop();
    }

    function calculateVotes() external isOwner {
        uint votes = 0;
        uint8 winnerIndex;

        for (uint8 i = 0; i < candidatesArr.length; i++) {
            candidatesArr[i].votes = candidates[
                candidatesArr[i].participantNumber
            ].votes;
            if (candidatesArr[i].votes > votes) {
                votes = candidatesArr[i].votes;
                winnerIndex = i;
            }
        }

        emit CalculateVotes(candidatesArr);
        if (votes > 0) emit WinnerCandidate(candidatesArr[winnerIndex]);
    }

    receive() external payable {
        payable(owner).transfer(msg.value); //why not
    }

    fallback() external payable {}
}
