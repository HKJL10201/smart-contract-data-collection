pragma solidity ^0.4.21;


contract VotingInterface {

//    @createTask is called for creating task, it sets the caller as the owner
//      of the task and sets the arguments as provided.
    function createTask(string taskName, uint256 taskEndingTime) public;

//    @getTaskInfo is called for getting all Info (address, name,
//      endingTime, VoteCount, AprrovedStatus and Complete Status) of a Task.
    function getTaskInfo(uint index) public view returns (address, string, uint, uint, bool, bool);

//    @registerMember is called for registering a member,
//     It handles if the member is already registered or not through a modifier @checkAddress.
    function registerMember() public;

//    @finalizeTask is called only by the owner of contract and
//      only when Time is over (current Time is greater that Task's ending time),
//      Task is neither approved, nor complete (no member voted false and not every member voted),
//     This all is done through modifiers.
    function finalizeTask(uint taskId) public;

//    @getTotalTasks returns total Number of Tasks that are registered (approved + not-approved + complete).
    function getTotalTasks() public view returns (uint);

//    @castVote is called for casting a vote to a Task.
//    It handles if member has not voted before to the same task.
//    If any member votes False it means now it is not possible for Task to get 100% votes(True) and to be approved in
//      anyways so it changes Approve status of Task to False and Complete to True and no one can vote anymore.
//    It checks at every vote cast if number of votes gets equal to totalMember it approves and completes Task
    function castVote(uint taskId, bool vote) public;


//    TaskCreated event gives length of Total Tasks everyTime when a new Task is created.
    event TaskCreated(uint);

//    MemberRegistered event gives length of Total Members everyTime when a new Member is registered.
    event MemberRegistered(uint);

//    VoteCasted event gives Address, Name, EndingTime, VoteCount, ApproveStatus, Complete Status
//      every time when a vote is casted, When vote is casted Tasks info get updated
//      so it is necessary to get Tasks latest Data.
    event VoteCasted(address, string, uint, uint, bool, bool);
}