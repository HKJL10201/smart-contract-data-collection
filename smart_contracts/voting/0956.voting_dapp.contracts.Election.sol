pragma solidity ^0.5.0;

contract Election {

    // Structures
    struct Candidate {
        string name;
        uint projectId;
        bool rankedProject;
        bool votedTeammates;
        uint points;
        mapping(uint => bool) votedProject;
    }

    struct Project {
        // id del proyecto
        uint id;
        string name;
        uint rank;
        uint count; // Number of people in a project
        uint timesRanked;
        mapping(uint => address) candidates;
        mapping(uint => uint) questionPoints;
        mapping(uint => uint) timesQuestAnswered;
    }

    // Mappings
    mapping(address => Candidate) public candidates;
    mapping(uint => Project) public projects;
    //mapping(uint => address) public candidatesList;

    // Variables
    uint8 private NUM_QUESTION = 4;

    address private admin;
    bool public appStarted;
    uint public userCount;
    uint public projectCount;


    constructor(address adminAddress) public {
        admin = adminAddress;
        appStarted = false;
        userCount = 0;
        projectCount = 0;
    }

    function addProject(string memory name) public payable {
        require(msg.sender == admin);
        require(appStarted == false); 
        projectCount++;
        projects[projectCount] = Project(projectCount, name, 0, 0, 0);
    }

    function addUser(address secAddress, uint projectId, string memory name) public payable {
        require(msg.sender == admin);
        require(appStarted == false);
        require(projects[projectId].id > 0);
        projects[projectId].count++;
        userCount++;
        //candidatesList[userCount] = secAddress;
        projects[projectId].candidates[projects[projectId].count]=secAddress;
        candidates[secAddress] = Candidate(name, projectId, false, false, 0);
    }

    function appStart() public payable {
        require(msg.sender == admin);
        require(appStarted == false);
        appStarted = true;
    }

    function getProjectCandidate(uint projectId, uint candidateNum) external view returns (address){
        return projects[projectId].candidates[candidateNum];
    }

    function getQuestionPoints(uint projectId) external view returns (uint, uint, uint, uint) { 
        return (projects[projectId].questionPoints[0], projects[projectId].questionPoints[1], projects[projectId].questionPoints[2], projects[projectId].questionPoints[3]);
    }

    function getTimesQuestAnswered(uint projectId) external view returns (uint, uint, uint, uint) { 
        return (projects[projectId].timesQuestAnswered[0], projects[projectId].timesQuestAnswered[1], projects[projectId].timesQuestAnswered[2], projects[projectId].timesQuestAnswered[3]);
    }
    

    function hasVoted(uint projectId) external view returns (bool) { 
        return (candidates[msg.sender].votedProject[projectId]);
    }

    function voteProject(uint projectId, uint[] memory votes) public payable {
        require(projectId > 0);
        require(projectId <= projectCount);
        require(appStarted == true);
        require(candidates[msg.sender].projectId > 0);
        require(candidates[msg.sender].projectId != projectId);
        require(candidates[msg.sender].votedProject[projectId] == false);
        require(votes.length == NUM_QUESTION);
  
        candidates[msg.sender].votedProject[projectId] = true;
        
        for(uint i = 0; i < votes.length; i++){
            projects[projectId].questionPoints[i] += votes[i];
            projects[projectId].timesQuestAnswered[i] += 1;
        }
    }

    function rankProject(uint[] memory votes) public payable {
        require(appStarted == true);
        require(candidates[msg.sender].projectId > 0);
        require(candidates[msg.sender].rankedProject == false);
  
        for(uint i = 0; i < votes.length; i++){
            projects[i+1].rank += votes[i];
            if (candidates[msg.sender].projectId != i+1) {
                projects[i+1].timesRanked += 1;
            }
        }
        candidates[msg.sender].rankedProject = true;
    }

    function voteTeammates(uint[] memory votes) public payable {
        require(appStarted == true); 
        Candidate memory user = candidates[msg.sender];
        require(user.projectId > 0);
        require(user.votedTeammates == false);
        require(votes.length == projects[user.projectId].count);
        // comprobaciones votes
        uint suma = 0;
        for (uint i = 0 ; i < votes.length; i++){
            suma+=votes[i];
        }
        require(suma == (projects[user.projectId].count + 1));
        for (uint i = 0 ; i < votes.length; i++){
            candidates[ projects[user.projectId].candidates[i+1] ].points+=votes[i];
        }
        candidates[msg.sender].votedTeammates = true;
    }

}