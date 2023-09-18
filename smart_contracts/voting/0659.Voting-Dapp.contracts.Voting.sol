// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;



contract Vote {
    address electionCommission;
    address public winner;
    struct Voter {
        string name;
        uint256 age;
        uint256 voterId;
        string gender;
        uint256 voteCandidateId;
        address voterAddress;
    }

    struct Candidate {
        string name;
        string party;
        uint256 age;
        string gender;
        uint256 candidateId;
        address candidateAddress;
        uint256 votes;
    }

    uint256 nextVoterId = 1;
    uint256 nextCandidateId = 1;
    uint256 startTime;
    uint256 endTime;
    mapping (address=> bool) isVoter;
    mapping(address=> bool) isCandidate;
    mapping(uint256 => Voter) voterDetails;
    mapping(uint256 => Candidate) candidateDetails;
    bool stopVoting=true;
    Voter[] private voteArr;
    uint x;
    uint y;


    constructor() {
        electionCommission = msg.sender;
    }

    modifier isVotingOver() {
        require(stopVoting==false , "Voting is over");
        _;
    }

    
        
    function voterRegister(
        string calldata _name,
        uint256 _age,
        string calldata _gender
    ) external returns (bool) {
        require(isVoter[msg.sender]!=true, "You have already registerd");
        require(_age >= 18, "You are not eligible to vote");
        voterDetails[nextVoterId] = Voter(
            _name,
            _age,
            nextVoterId,
            _gender,
            0,
            msg.sender
        );
        isVoter[msg.sender]=true;
        nextVoterId++;
        return true;
    }

    function vote(uint256 _voterId, uint256 _id) external isVotingOver {
        require(isVoter[msg.sender]==true,"you are not registered");

        require(
            voterDetails[_voterId].voteCandidateId == 0,
            "You have already voted"
        );
        require(
            voterDetails[_voterId].voterAddress == msg.sender,
            "You are not a voter"
        );
        
        require(startTime != 0 && block.timestamp>startTime, "Voting has not started");
        require(endTime>block.timestamp, "voting is over");
        require(nextCandidateId > 2, "There are no candidates to vote");
        require(_id < 3, "Candidate does not exist");
        voterDetails[_voterId].voteCandidateId = _id;
        candidateDetails[_id].votes++;
    }

    function candidateRegister(
        string calldata _name,
        string calldata _party,
        uint256 _age,
        string calldata _gender
    ) external {
        require(
            isCandidate[msg.sender]!=true,
            "You have already registerd"
        );
        require(_age >= 18, "You are not eligible to be a candidate");
        require(nextCandidateId < 3, "Registration is full");
        candidateDetails[nextCandidateId] = Candidate(
            _name,
            _party,
            _age,
            _gender,
            nextCandidateId,
            msg.sender,
            0
        );
        nextCandidateId++;
        isCandidate[msg.sender]=true;
    }

    function result() external {
        require(
            msg.sender == electionCommission,
            "You are not from election commision"
        );
        require(stopVoting==false,"first continue voting that has been stopped");
        require(endTime<block.timestamp,"voting is going on");
        //require - for timings
        //require- emergency
        //require- to check whether candidates have registered for this or not
        Candidate[] memory arr = new Candidate[](nextCandidateId - 1);
        arr = candidateList();

        if (arr[0].votes > arr[1].votes) {
            winner = arr[0].candidateAddress;
        } else {
            winner = arr[1].candidateAddress;
        }
    }

    function candidateList() public view returns (Candidate[] memory) {
        Candidate[] memory arr = new Candidate[](nextCandidateId - 1);

        for (uint256 i = 1; i < nextCandidateId; i++) {
            arr[i - 1] = candidateDetails[i];
        }
        return arr;
    }

    function voterList() external view returns (Voter[] memory) {
        Voter[] memory arr = new Voter[](nextVoterId - 1);
        for (uint256 i = 1; i < nextVoterId; i++) {
            arr[i - 1] = voterDetails[i];
        }
        return arr;
    }

    function voteTime(uint256 _startTime, uint256 _endTime) external {
        require(
            msg.sender == electionCommission,
            "You are not from Election Commision"
        );
        startTime = block.timestamp + _startTime;
        endTime = startTime + _endTime;
        stopVoting = false;
    }

    function votingStatus() public view returns (string memory) {
        if (startTime == 0) {
            return "Not Started";
        } else if (
            (startTime != 0 && endTime > block.timestamp) && stopVoting == false
        ) {
            return "In progress";
        } else {
            return "Ended";
        }
    }

    function emergency() public {
        require(msg.sender==electionCommission,"you are not from election commision");
        stopVoting = true;
        x=block.timestamp;
    }
    function freeEmergency() public{
        require(msg.sender==electionCommission,"you are not from election commision");
        if(stopVoting==true)
        {
            stopVoting=false;
            y=block.timestamp;
            uint a=y-x;
            endTime=a+endTime;
        }
    }
}



// Candidate Registration Page
// Candidate Login Page
// Voter Registration Page
// Voter Login Page
