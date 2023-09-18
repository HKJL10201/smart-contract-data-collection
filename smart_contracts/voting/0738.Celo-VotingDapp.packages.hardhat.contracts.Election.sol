// SPDX-License-Identifier:GPL-3.0

pragma solidity >=0.7.0 < 0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract Election {
    using Counters for Counters.Counter;
    Counters.Counter public candidateId;
    Counters.Counter public votersId;

    // Candidate Data
    struct Candidate {
       uint256 canditateId;
       string name;
       address candidateAddress;
       uint256 voteCount;
    }
    event LogCandidate(
        uint256 canditateId,
        string name,
        address candidateAddress,
        uint256 voteCount
    ); 
    address[] public candidateAddresses;
    mapping(address => Candidate) public candidates;

    // Voters Data
    struct Voter {
        uint256 voterId;
        bool voted;
        uint256 weight;
        uint256 vote;
        address voterAddress;
        string voterName;
    }
    event LogVoter (
        bool voted,
        uint256 weight,
        uint256 vote,
        address voterAddress
    );

    address[] public votedVoters;
    address[] public votersAddresses;
    mapping(address => Voter) public voters;

    address public chairperson;
    uint256 private votingStartTime = block.timestamp;
    uint256 private votingEndTime;

    modifier onlyOwner {
        require(msg.sender == chairperson, "You are not the chairperson");
        _;
    }

    modifier votingStatus{
        require(block.timestamp >= votingStartTime, "Voting Ongoing");
        require(block.timestamp <= votingEndTime, "Voting has ended");
        _;
    }

    constructor() {
        chairperson =  msg.sender;
        votingEndTime = votingStartTime + 2 hours;
    }

    function addCandidate(string memory _name, address _candidateAddress) public  onlyOwner votingStatus {
        require(candidates[_candidateAddress].candidateAddress == address(0), "candidate already registered");
        require(_candidateAddress != chairperson, "Chairperson cannot be a candidate");

        candidateId.increment();
        uint256 id = candidateId.current();
        Candidate storage candidate = candidates[_candidateAddress];
        candidate.canditateId = id;
        candidate.candidateAddress = _candidateAddress;
        candidate.name = _name;
        candidate.voteCount = 0;
        candidateAddresses.push(_candidateAddress);
        emit LogCandidate(id, _name, _candidateAddress, 0); 
    }

    function getCandidates() public view returns (address[] memory){
        return candidateAddresses;
    }

    function getCandidateLength() public view returns (uint256){
        return candidateAddresses.length;
    }

    function getCandidateData(address _candidateAddress) public view returns(uint256, string memory, address, uint256){
        return(
            candidates[_candidateAddress].canditateId,
            candidates[_candidateAddress].name,
            candidates[_candidateAddress].candidateAddress,
            candidates[_candidateAddress].voteCount
        );
    }

    function giveVoterRight(address _voterAddress) public onlyOwner votingStatus{
        votersId.increment();
        uint256 id = votersId.current();
        Voter storage voter = voters[_voterAddress];
        require(voter.weight == 0, "You have already registered");
        voter.voterId = id;
        voter.weight = 1;
        voter.voterAddress = _voterAddress;
        voter.voted = false;
        votersAddresses.push(_voterAddress);
    }

    function vote(address _candidateAddress, uint256 _candidate_id) public votingStatus {
        Voter storage voter = voters[msg.sender];
        require(!voter.voted, "You have already voted");
        require(voter.weight != 0,  "You don't have right to vote");
        require( _candidateAddress == candidates[_candidateAddress].candidateAddress,  "Candidate does not exist");

        voter.voted = true;
        voter.vote = _candidate_id;

        votedVoters.push(msg.sender);

        candidates[_candidateAddress].voteCount += voter.weight;
         emit LogVoter (true, voter.weight, _candidate_id, msg.sender);
    }

    function getVoterLength() public view returns (uint256) {
        return votersAddresses.length;
    }

    function getVoterData(address _voterAddress) public view returns (uint256,bool,uint256,uint256,address,string memory) {
        return(
            voters[_voterAddress].voterId,
            voters[_voterAddress].voted,
            voters[_voterAddress].weight,
            voters[_voterAddress].vote,
            voters[_voterAddress].voterAddress,
            voters[_voterAddress].voterName
        );
    }

    function getVotedVoters() public view returns (address [] memory) {
        return votedVoters;
    }

    function getVoterList() public view returns (address [] memory) {
        return votersAddresses;
    }

     /**
     * @dev Gives ending epoch time of voting
     * @return _endTime When the voting ends
     */
    function getVotingEndTime() public view returns (uint256 _endTime) {
        return votingEndTime;
    }

    /**
     * @dev used to update the voting start & end times
     * @param _startime Start time that needs to be updated
     */
    function updateVotingStartTime(uint256 _startime)
        public
        onlyOwner
    {
        require(votingStartTime >= _startime);
        votingStartTime += _startime;
    }

    /**
     * @dev To extend the end of the voting
     * @param _endTime End time that needs to be updated
     */
    function extendVotingEndTime(uint256 _endTime)
        public
        onlyOwner
    {
        // require(block.timestamp >= votingEndTime, "voting has not ended");
        votingEndTime += _endTime;
    }

    // Get winner address and voterCount
    function getWinner() public onlyOwner view returns (address _winningCandidate, uint256 _voteCount ) {
        require(votingEndTime < block.timestamp, "Please wait for voting to end to see the result");
        uint voteCount = 0;
        address winnerAddress;
        for(uint256 i=0; i<candidateAddresses.length; i++) {
            if(candidates[candidateAddresses[i]].voteCount > voteCount) {
                voteCount = candidates[candidateAddresses[i]].voteCount;
                winnerAddress = candidateAddresses[i];
            }
        }
        return (winnerAddress, voteCount);
    }

}
  