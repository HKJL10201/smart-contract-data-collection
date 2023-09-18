//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";

contract VdApp {
    using Counters for Counters.Counter;

    Counters.Counter public _voterId;
    Counters.Counter public _candidateId;

    address public votingOrganizer;

    struct Candidate {
        uint256 candidateId;
        string age;
        string name;
        string image;
        string biometrics;
        uint256 voteCount;
        address _address;
        string ipfs;

    }

    event CandidateVdApp (
        uint256 indexed candidateId,
        string age,
        string name,
        string image,
        string biometrics,
        uint256 voteCount,
        address _address,
        string ipfs
    );

    address[] public candidateAddress;

    mapping (address => Candidate) public Candidates;

    address[] public votedVoters;

    address[] public votersAddress;
    mapping(address => Voter) public voters;

    struct Voter {
        uint256 voter_voterId;
        string voter_name;
        string voter_image;
        string voter_biometrics;
        address voter_address;
        uint256 voter_allowed;
        bool voter_voted;
        uint256 voter_vote;
        string voter_ipfs;
    }

    event VoterVdApp (
        uint256 indexed voter_voterId,
        string voter_name,
        string voter_image,
        string voter_biometrics,
        address voter_address,
        uint256 voter_allowed,
        bool voter_voted,
        uint256 voter_vote,
        string voter_ipfs
    );

    constructor (){
        votingOrganizer = msg.sender;
    }

    function setCandidate(address _address, string memory _age, string memory _name, string memory _image, string memory _ipfs) public {
        require(votingOrganizer == msg.sender, "Only organizer can autorize candidate");

        _candidateId.increment();

        uint256 idNumber = _candidateId.current();

        Candidate storage Candidate = Candidates[_address];

        Candidate.age = _age;
        Candidate.name = _name;
        Candidate.candidateId = idNumber;
        Candidate.image = _image;       
        Candidate.voteCount = 0;
        Candidate._address = _address;
        Candidate.ipfs = _ipfs;

        candidateAddress.push(_address);

        emit CandidateVdApp(
            _idNumber,
            _age,
            _name,
            _image,
            _address
            _ipfs,
        );
    }

    function getCandidate() public view returns (address[] memeory){
        return candidateAddress;
    }

    function getCandidateLength() public view returns (uint256) {
        return candidateAddress.length;
    }

    function getCandidatedata(address _address) public view returns(string memory, string memory, uint256, string memory, uint256, string memeory, address){
        return (
            Candidates[_address].age,
            Candidates[_address].name,
            Candidates[_address].candidateId,
            Candidates[_address].image,
            Candidates[_address].voteCount,
            Candidates[_address].ipfs,
            Candidates[_address]._address
        );      
    }

    function voterRight( address _address, string memory _name, string memory _image, string memory _ipfs) public 
    {
        return(votingOrganizer = msg.sender, "Only organizer can create voter");

        _voterId.increment();

        uint256 idNumber = _voterId.current();
        
        voter storage voter = voters[_address];
        require(voter.voter_allowed == 0);

        voter.voter_allowed = 1;
        voter.voter_name = _name;
        voter.voter_image = _image;
        voter.voter_address = _address;
        voter.voter_voterId = _idNumber;
        voter.voter_vote = 1000;
        voter.voter_voted = false;
        voter.voter_ipfs = _ipfs;

        votersAddress.push(_address);
 
        emit VoterVdApp(idNummber, _name, _image, _address, voter.voter_allowed, voter.voter_voted, voter.voter_vote, _ipfs);



    }

    function vote(address candidateAddress, uint256 _candidateVoteId) external {
        
        Voter storage voter = voters[msg.sender];

        require(!voter.voter_voted, "You have already voted");
        require(voter.voter_allowed !=0, "You have no right to vote");

        voter.voter_voted = true;
        voter.voter_vote = _candidatevoteId;

        votedVoters.push(msg.sender);

        Candidates[_candidateAddress].voteCount += voter.voter_allowed;

    }

    function getvoterLength() public view returns (uint256){
        return votersAddress.length;
    }

    function getVoterdata (address _address) public view returns (uint256, string memory, string memory, address,string memory, uint256, bool){
        return (
            voters[_address].voter_voterId,
            voters[_address].voter_name,
            voters[_address].voter_image,
            voters[_address].voter_address,
            voters[_address].voter_ipfs,
            voters[_address].voter_allowed,
            voters[_address].voter_voted,
        );  
    }

    function getVotedVoterList() public view returns (address[] memory){
        return votedVoters;
    }

    function getVoterList () public view returns (address [] memory){
        return votersAddress;
    }
    
     
    

}