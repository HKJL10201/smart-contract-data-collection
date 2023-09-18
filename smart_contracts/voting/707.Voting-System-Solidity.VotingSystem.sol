// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract VotingSystem {
    
    address public electionAdmin;
    address public winnerAddress;
    string public eventName;
    uint public totalVote;
    bool votingStarted;

    struct Candidate{
        string canName;
        uint canAge;
        bool canRegistered;
        address canAddress;
        uint canVotes;
    }

    struct Voter{
        bool registered;
        bool voted;
    }

    event success(string msg);

    mapping(address=>uint) public candidates;
    mapping(address=>Voter) public voterList;
    Candidate[] public candidateList;

    constructor(string memory _eventName){
        electionAdmin = msg.sender;
        eventName = _eventName;
        totalVote = 0;
        votingStarted = false;
    }

    function registerCandidates(string memory _canName, uint _canAge, address _canAddress) public {
        require(msg.sender == electionAdmin, "Only Election Commision can register Candidate!!");
        require(_canAddress != electionAdmin, "Election Commision can not participate!!");
        require(candidates[_canAddress] == 0, "Candidate already registered");
        Candidate memory candidate = Candidate({
            canName: _canName,
            canAge: _canAge,
            canRegistered: true,
            canVotes: 0,
            canAddress: _canAddress
        });

        if(candidateList.length == 0){ 
            candidateList.push();
        }

        candidates[_canAddress] = candidateList.length;
        candidateList.push(candidate);
        emit success("Candidate registered!!");
    }

    function whiteListAddress(address _voterAddress) public {
        require(_voterAddress != electionAdmin, "Election Commision can not vote!!");
        require(msg.sender == electionAdmin, "Only Election Commision can whitelist the addresses!!");
        require(voterList[_voterAddress].registered == false, "Voter already registered!!");
        Voter memory voter = Voter({
            registered: true,
            voted: false
        });

        voterList[_voterAddress] = voter;
        emit success("Voter registered!!");
    }

    function startVoting() public {
        require(msg.sender == electionAdmin, "Only electionAdmin can start voting!!");
        votingStarted = true;
        emit success("Voting Started!!");
    }

    function putVote(address _canAddress) public {
        require(votingStarted == true, "Voting not started yet or ended!!");
        require(msg.sender != electionAdmin, "electionAdmin can not vote!!");
        require(voterList[msg.sender].registered == true, "Voter not registered!!");
        require(voterList[msg.sender].voted == false, "Already voted!!");
        require(candidateList[candidates[_canAddress]].canRegistered == true, "Candidate not registered");

        candidateList[candidates[_canAddress]].canVotes++;
        voterList[msg.sender].voted =true;

        uint candidateVotes = candidateList[candidates[_canAddress]].canVotes;

        if(totalVote < candidateVotes){
            totalVote = candidateVotes;
            winnerAddress = _canAddress;
        }
        emit success("Voted !!");
        
    }

    function stopVoting() public {
        require(msg.sender == electionAdmin, "Only electionAdmin can start voting!!");
        votingStarted = false;
        emit success("Voting stoped!!");
    }

    function getAllCandidate() public view returns(Candidate[] memory list){
        return candidateList;
    }

    function votingStatus() public view returns(bool){
        return votingStarted;
    }

    function getWinner() public view returns(Candidate memory candidate){
        require(msg.sender == electionAdmin, "Only electionAdmin can declare winner!!");
        return candidateList[candidates[winnerAddress]];
    }

}