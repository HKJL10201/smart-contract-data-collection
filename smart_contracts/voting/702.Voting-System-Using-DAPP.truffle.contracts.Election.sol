//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;
import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";

contract Election {
    using Counters for Counters.Counter;

    Counters.Counter public _voterId;
    Counters.Counter public _candidateId;

    address public votingOrganizer;
    address public winner;

    //Candidate For Voting

    address[] public candidateAddress;

    struct Candidate {
        uint256 candidateId;
        string age;
        string name;
        uint256 voteCount;
        address _address;
    }

    event CandidateCreate(
        uint256 candidateId,
        string age,
        string name,
        uint256 voteCount,
        address _address
    );

    mapping(address => Candidate) public candidates;

    // Voters Data

    address[] public votedVoters;
    address[] public votersAdress;

    struct Voter {
        uint256 voter_voterId;
        string voter_name;
        string voter_age;
        address voter_address;
        uint256 voter_allowed;
        bool voter_voted;
        uint256 voter_vote;
    }

    event VoterCreated(
        uint256 indexed voter_voterId,
        string voter_name,
        string voter_age,
        address voter_address,
        uint256 voter_allowed,
        bool voter_voted,
        uint256 voter_vote
    );

    mapping(address => Voter) public voters;

    //Constructor

    constructor() {
        votingOrganizer = msg.sender;
    }

    //----------Functions for createCandidate----------

    function setCandidate(
        address _address,
        string memory _age,
        string memory _name
    ) public {
        require(
            votingOrganizer == msg.sender,
            "Only Organizer can Create Candidate"
        );

        _candidateId.increment();

        uint256 idNumber = _candidateId.current();

        Candidate storage candidate = candidates[_address];

        candidate.age = _age;
        candidate.name = _name;
        candidate.candidateId = idNumber;
        candidate.voteCount = 0;
        candidate._address = _address;

        candidateAddress.push(_address);

        emit CandidateCreate(
            idNumber,
            _age,
            _name,
            candidate.voteCount,
            _address
        );
    }

    //getCandidate fnction to get all candidate

    function getCandidate() public view returns (address[] memory) {
        return candidateAddress;
    }

    //get candidate length function

    function getCandidateLength() public view returns (uint256) {
        return candidateAddress.length;
    }

    // get data of a candidate

    function getCandidateData(address _address)
        public
        view
        returns (
            string memory,
            string memory,
            uint256,
            uint256,
            address
        )
    {
        return (
            candidates[_address].age,
            candidates[_address].name,
            candidates[_address].candidateId,
            candidates[_address].voteCount,
            candidates[_address]._address
        );
    }

    //----------Functions for Voter----------

    //give access to the voter to vote function

    function voterRight(
        address _address,
        string memory _name,
        string memory _age
    ) public {
        require(
            votingOrganizer == msg.sender,
            "Only organizer can creat the voter"
        );

        _voterId.increment();

        uint256 idNumber = _voterId.current();

        Voter storage voter = voters[_address];

        require(voter.voter_allowed == 0, "Voter is already register");

        voter.voter_allowed = 1;
        voter.voter_name = _name;
        voter.voter_age = _age;
        voter.voter_address = _address;
        voter.voter_voterId = idNumber;
        voter.voter_vote = 500;
        voter.voter_voted = false;

        votersAdress.push(_address);

        emit VoterCreated(
            idNumber,
            _name,
            _age,
            _address,
            voter.voter_allowed,
            voter.voter_voted,
            voter.voter_vote
        );
    }

    // give vote to someone function

    function vote(address _candidateAddress, uint256 _candidateVoteId) external {
        Voter storage voter = voters[msg.sender];

        require(!voter.voter_voted, "You have already voted");
        require(voter.voter_allowed != 0, "You have no right to vote");

        voter.voter_voted = true;
        voter.voter_vote = _candidateVoteId;
        
        votedVoters.push(msg.sender);

        candidates[_candidateAddress].voteCount += voter.voter_allowed;

    }

    // get voter length function

    function getVoterLength() public view returns (uint256) {
        return votersAdress.length;
    }

    // get voter detils function

    function getVoterData(address _address) public view returns (uint256, string memory, address, uint256, bool) {
        return (
            voters[_address].voter_voterId,
            voters[_address].voter_name,
            voters[_address].voter_address,
            voters[_address].voter_allowed,
            voters[_address].voter_voted
        );
    }

    //get all voted voter list function

    function getVotedVoterList() public view returns (address[] memory){
        return votedVoters;
    }

    //get all the voter list function

    function getVoterList() public view returns (address[] memory) {
        return votersAdress;
    }

    //Check winner

    function getWinner() public returns (string memory,string memory,uint256,uint256,address) {
        uint x;
        for (uint i=0;i<candidateAddress.length;i++){
            address temp = candidateAddress[i];
            if(candidates[temp].voteCount > x){
                winner = temp;
            }             
        }
        return (
            candidates[winner].age,
            candidates[winner].name,
            candidates[winner].candidateId,
            candidates[winner].voteCount,
            candidates[winner]._address

        );
    }

}
