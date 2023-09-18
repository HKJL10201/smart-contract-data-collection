// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


/*
 Voting audience enum
 Reminder: Enums are interpreted as uint8 in method parameters.
 Example of use:  Set `employees` as allowed voters:
 `Audience public audience = 1;` or
 `Audience public audience = Audience.employees;`
*/

enum Audience {
    students, // 0
    employees, // 1
    all  // 2
}

contract VotingFactory {
    address public owner;
    address[] public deployedVotings;
    mapping(address => bool) public students;
    mapping(address => bool) public employees;

    constructor () {
        owner = msg.sender;
    }

    modifier onlyBy(address _account) {
        require(
            msg.sender == _account,
            "Sender not authorized."
        );
        _;
    }

    modifier communityRestricted() {
        require(students[msg.sender] == true || employees[msg.sender] == true, "Only students and employees can call this function");
        _;
    }

    function createVoting(string memory topic, string[] memory options, Audience audience) public communityRestricted() {
        require(keccak256(abi.encodePacked(topic)) != keccak256(abi.encodePacked("")), "Topic must be provided"); // check if topic is not empty
        require(options.length > 1, "At least two options must be provided"); // check if there are at least two options
        require(options.length <= 10, "No more than 10 options can be provided"); // check if max options is exceeded
        require(audience >= Audience.students && audience <= Audience.all, "Provided audience does not exist"); // check if provided audience is valid
        address newVoting = address(new Voting(address(this), msg.sender, topic, options, audience));
        deployedVotings.push(newVoting);
    }

    function addStudent(address _address) public onlyBy(owner) {
        students[_address] = true;
    }

    function addEmployee(address _address) public onlyBy(owner) {
        employees[_address] = true;
    }

    function removeStudent(address _address) public onlyBy(owner) {
        delete students[_address];
    }

    function removeEmployee(address _address) public onlyBy(owner) {
        delete employees[_address];
    }

    function isEmployee(address _address) public view returns (bool) {
        return employees[_address];
    }

    function isStudent(address _address) public view returns (bool) {
        return students[_address];
    }

    function getDeployedVotings() public view returns (address[] memory) {
        return deployedVotings;
    }
}

contract Voting {
    address public creator;
    address private factoryAddress;
    VotingFactory private factory;
    string public topic;
    string[] public options;
    mapping(string => uint) public optionsVotes;
    mapping(address => bool) public voters;
    uint public votersCount;
    bool public closed;
    Audience public audience;

    modifier restricted() {
        require(msg.sender == creator, "Only creator can call this function");
        _;
    }

    modifier onlyByAudience() {
        if (audience == Audience.all) {
            require(factory.isStudent(msg.sender) || factory.isEmployee(msg.sender), "Only students and employees can call this function");
        } else if (audience == Audience.students) {
            require(factory.isStudent(msg.sender), "Only students can call this function");
        } else if (audience == Audience.employees) {
            require(factory.isEmployee(msg.sender), "Only employees can call this function");
        }
        _;
    }

    constructor (address _factoryAddress, address _creator, string memory _topic, string[] memory _options, Audience _audience) {
        creator = _creator;
        factoryAddress = _factoryAddress;
        factory = VotingFactory(factoryAddress);
        topic = _topic;
        options = _options;
        audience = _audience;
    }

    function vote(string memory option) public onlyByAudience() {
        require(!voters[msg.sender], "You have already voted");
        require(!closed, "Voting is closed");
        bool optionExists = false;
        for(uint i = 0; i < options.length; i++) {
            if(keccak256(abi.encodePacked(options[i])) == keccak256(abi.encodePacked(option))) {
                optionExists = true;
                break;
            }
        }
        require(optionExists, "Option does not exist");
        voters[msg.sender] = true;
        optionsVotes[option] += 1;
        votersCount += 1;
    }

    function closeVoting() public restricted {
        require(!closed, "Voting is already closed");
        closed = true;
    }

    function getSummary() public view returns (
        address, string memory, uint, bool, string memory
    ) {
        return (
            creator,
            topic,
            votersCount,
            closed,
            getAudienceToString()
        );
    }

    function getOptions() public view returns (string[] memory) {
        return options;
    }

    function getOptionVotes(string memory option) public view returns (uint) {
        return optionsVotes[option];
    }

    function getVotersCount() public view returns (uint) {
        return votersCount;
    }

    function getOptionsCount() public view returns (uint) {
        return options.length;
    }

    function getAudienceToString() public view returns(string memory){
        if(audience == Audience.students){
            return "students";
        } else if(audience == Audience.employees){
            return "employees";
        } else {
            return "all";
        }
    }
}