// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Voting {

    address public constant ADMIN = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    uint public totalVotes;
    bool public voteStart;
    bool public voteEnd;
    string[] candidateList;
    event Winner(Candidate _candidate);
    
    struct Candidate {
        address candidateAddr;
        string name;
        bool candRegistered;
        uint votes; 
    }
    mapping(uint => Candidate) public candidates;
    Candidate public winner;
    uint public candidateNum;


  
    bool voted;
    
    mapping(address => bool) public voters;
    uint public voterNum;

    modifier onlyAdmin() {
        require(msg.sender == ADMIN, "You are not ADMIN");
        _;
    }

    function registerCandidate(address _candidateAddr,string calldata name) external onlyAdmin() {
        require(msg.sender == ADMIN, "You are not ADMIN");
        require(_candidateAddr != ADMIN, "Admin cannot become a candidate");
        require(voteStart == false, "Voting has started");
        candidates[candidateNum] = Candidate(_candidateAddr, name,true, 0);
        candidateList.push(candidates[candidateNum].name);
        ++candidateNum;
    }

    function vote(uint _candidateNum) external {
        require(voteStart == true && voteEnd == false, "You cannot vote now");
        require(voters[msg.sender] == false, "You already voted");
        require(candidates[_candidateNum].candRegistered == true, "candidate not found");
        Candidate storage _candidateVote = candidates[_candidateNum];
        _candidateVote.votes += 1;
        voters[msg.sender] = true;
        ++voterNum;
        ++totalVotes;
    }


    function startVoting() external onlyAdmin() {
        voteStart = true;
    }

    function endVoting() external onlyAdmin() {
        voteEnd = true;
        voteStart = false;
    }

    function showCandidates() external view returns(string[] memory) {
        return candidateList;
    }

    function Result() external onlyAdmin() returns(Candidate memory) {
        require(voteEnd = true, "Voting not ended yet");
        winner = candidates[0];
        for(uint i=0; i<=candidateNum; ++i) {
            if(winner.votes < candidates[i].votes) { 
                winner = candidates[i];
            }
        } 
        return winner;
        emit Winner(winner);
    }


}
