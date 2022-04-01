pragma solidity ^0.5.0;

contract Election {

    // Structures
    struct User {
        //address secAddress;
        bool votedProject;
        bool votedTeammates;
        uint projectId;
    }

    struct Candidate {
        // id
        string name;
        uint projectId;
        uint points;
    }

    struct Project {
        // id del projecto
        uint id;
        string name;
        uint points;
        uint count; // Number of people in a proyect
        mapping(uint => uint) candidates;
    }

    // Mappings
    mapping(address => User) public users;
    mapping(uint => Candidate) public candidates;
    mapping(uint => Project) public projects;

    // Variables
    address private admin;
    bool public appStarted;
    uint public userCount;
    uint public projectCount;

    // Events
    // event votedEvent (
    //     uint indexed _candidateId
    // );

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
        projects[projectCount] = Project(projectCount, name, 0, 0);
    }

    function addUser(address secAddress, uint projectId, string memory name) public payable {
        require(msg.sender == admin);
        require(appStarted == false);
        require(projects[projectId].id > 0);
        projects[projectId].count++;
        userCount++;
        projects[projectId].candidates[projects[projectId].count]=userCount;
        users[secAddress] = User(false, false, projectId);
        candidates[userCount] = Candidate(name, projectId, 0);
    }

    function appStart() public payable {
        require(msg.sender == admin);
        require(appStarted == false);
        appStarted = true;
    }

    function voteProject(uint[] memory votes) public payable {
        require(appStarted == true);
        User memory user = users[msg.sender];
        require(user.projectId > 0);
        require(user.votedProject == false);

        require(votes.length == projectCount);
        require(votes[user.projectId-1] == 0);
        // comprobaciones
        for(uint i = 0; i < votes.length; i++){
            projects[i+1].points+=votes[i];
        }
        // user.votedProject = true;
        users[msg.sender].votedProject = true;
    }

    function voteTeammates(uint[] memory votes) public payable {
        require(appStarted == true); 
        User memory user = users[msg.sender];
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
            candidates[ projects[user.projectId].candidates[i] + 1].points+=votes[i];
        }
        users[msg.sender].votedTeammates = true;
    }

}