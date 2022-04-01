

pragma solidity ^0.4.21;
import "./VotingInterface.sol";

contract VotingSystem is VotingInterface {
    struct Task {
        address taskOwner;
        string name;
        uint endingTime;
        uint voteCount;
        bool approved;
        bool complete;
        mapping(address => bool) votes;
    }
    Task[] public tasks;

    address public owner;
    mapping(address => bool) public members;
    uint public totalMembers; // ---> A separate Var to return total Members

    constructor() public {
        owner = msg.sender;
    }

    modifier checkAddress (address sender) {
        require(!members[sender]);
        _;
    }
    modifier ifMember (address sender) {
        require(members[sender]);
        _;
    }

    function registerMember() checkAddress(msg.sender) public {
        members[msg.sender] = true;
        totalMembers++;
        emit MemberRegistered(totalMembers);
    }

    function createTask (string taskName, uint256 taskEndingTime) ifMember(msg.sender) public {
        Task memory newTask = Task({
            taskOwner: msg.sender,
            name: taskName,
            endingTime: taskEndingTime,
            approved: false,
            complete: false,
            voteCount: 0
        });
        tasks.push(newTask);
        emit TaskCreated(tasks.length);
    }

    function getTaskInfo (uint index) public view returns(address, string, uint, uint, bool, bool) {
        Task storage temp = tasks[index];
        return (temp.taskOwner, temp.name, temp.endingTime, temp.voteCount, temp.approved, temp.complete);
    }

    function checkVoted(uint index) public view returns(bool) {
        Task storage temp = tasks[index];
        return temp.votes[msg.sender];
    }

    function getTotalTasks() public view returns(uint) {
        return tasks.length;
    }

    function finalizeTask(uint taskId) public {
        require(members[msg.sender] == true);

        Task storage task = tasks[taskId];
        require(msg.sender == task.taskOwner);
        task.complete = true;
    }

    function castVote(uint taskId, bool vote) public {
        require(members[msg.sender] == true);

        Task storage task = tasks[taskId];

        require(!task.votes[msg.sender]);
        require(task.endingTime > now);
        require(task.complete != true);

        if(vote) {
            task.votes[msg.sender] = vote;
            task.voteCount++;
            if(task.voteCount == totalMembers) {
                task.complete = true;
                task.approved = true;
            }
        }
        else {
            task.votes[msg.sender] = false;
            task.complete = true;
        }
        emit VoteCasted(task.taskOwner, task.name, task.endingTime, task.voteCount, task.approved, task.complete);
    }
}