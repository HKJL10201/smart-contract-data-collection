//SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.9.0;

contract Voting{

    struct Candidate{
        string name;
        string party;
        address adr;
        uint age;
        uint votes;
        uint id;
    }

    struct Voter{
        string name;
        address adr;
        uint age;
        bool voted;
        uint id;
    }
    
    uint countCandidates=0;
    uint countVoters=0;
    mapping(address=>Candidate) candidates;
    mapping(address=>Voter) voters;
    Candidate[] public candidatesList;
    address public result;
    address public electionCommission;
    uint public startTime;
    uint public endTime;

    constructor(){
        electionCommission=msg.sender;
    }

    function registerCandidate(string memory _name, string memory _party, uint _age) external{
        require(msg.sender!=electionCommission,"You are election commissioner");
        require(_age>=18,"You must be above 18 years to register");
        require(candidates[msg.sender].id==0,"You have already registered");
        require(voters[msg.sender].id==0,"You have already registered as a voter");
        require(countCandidates<2,"Only 2 candidates can register");
        countCandidates++;
        Candidate memory candidate=Candidate(_name,_party,msg.sender,_age,0,countCandidates);
        candidatesList.push(candidate);
        candidates[msg.sender]=candidate;
    }

    function registerVoter(string memory _name, uint _age) external{
        require(msg.sender!=electionCommission,"You are election commissioner");
        require(_age>=18,"You must be above 18 years to register");
        require(voters[msg.sender].id==0,"You have already registered");
        require(candidates[msg.sender].id==0,"You have already registered as a candidate");
        countVoters++;
        Voter memory voter=Voter(_name,msg.sender,_age,false,countVoters);
        voters[msg.sender]=voter;
    }

    function vote(address candidateAddress) external{
        require(msg.sender!=electionCommission,"You are election commissioner");
        require(voters[msg.sender].id>0,"You have not registered");
        require(voters[msg.sender].voted==false,"You have already voted");
        require(candidates[candidateAddress].id>0,"Candidate is not registered");
        require(block.timestamp>=startTime || startTime==0, "Voting period has not started");
        require(block.timestamp<=endTime, "Voting period has ended");
        voters[msg.sender].voted=true;
        candidates[candidateAddress].votes++;
        uint id=candidates[candidateAddress].id;
        candidatesList[id-1]=candidates[candidateAddress];
    }

    function startVoting(uint _start, uint _end) external{
        require(msg.sender==electionCommission,"Only election commissioner can start the election");
        require(countCandidates==2,"2 candidates have not registered yet");
        startTime=block.timestamp+_start;
        endTime=startTime+_end;
    }

    function declareResult() external{
        require(msg.sender==electionCommission,"Only election commissioner can view the result");
        require(block.timestamp>endTime,"You can view the result only after the voting period ends");
        if(candidatesList[0].votes>candidatesList[1].votes){
            result=candidatesList[0].adr;
        }else if(candidatesList[0].votes<candidatesList[1].votes){
            result=candidatesList[1].adr;
        }else{
            result=address(0);
        }
    }
}