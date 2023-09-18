// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract voting
{
   // mapping (uint=>address ) public data;
    address public EC;
    uint public totalseats;
    uint public deadline;
    uint public RemainingSeats;
    struct Voter
    {
        address person;
        string name;
        uint NIC;
        uint Age;
        bool voted;
    }
    mapping(address=>Voter) public voters;
    // uint public persondata;
     uint public totalvoter;
    struct Candidate
    {
        address candi;
        string Name;
        string Post;
        uint age;
        bool isregistered;
        uint noofvotes;
    }
    mapping (address=>Candidate) public candidates;
    uint public TotalCandidates;
    constructor(uint _totalseats,uint _deadline)
    {
        totalseats = _totalseats;
        RemainingSeats =totalseats;
        deadline = block.timestamp+ _deadline;
        EC = msg.sender;
    }
    function voterRigstration(string memory _name,uint _NIC,uint _age) public 
    {
        require(msg.sender!=EC,"EC are not capable for registration");
        require(bytes(_name).length>0,"Please enter name");
        require(_NIC > 0,"Please enter NIC number");
        require(_age>18,"You are under age");
        require(deadline>block.timestamp,"TimeUP for voting");
        require(!voters[msg.sender].voted ,"Already registered");
        voters[msg.sender] = Voter({
            person: msg.sender,
            name: _name,
            NIC: _NIC,
            Age:_age,
            voted:true
        });
        totalvoter++;
    }
    function RegisterCandidate(string memory _name,string memory _post,uint _age) public
    {
        require(bytes(_name).length >0,"Please Enter Name");
        require(bytes(_post).length>0,"Please choose Post ");
        require(_age >= 24,"Your age must be greater then 24");
        require(msg.sender!=EC,"EC are not able for registration");
        require(deadline > block.timestamp,"Time Up");
        require(!candidates[msg.sender].isregistered,"Already Registered");
        candidates[msg.sender] = Candidate({
            candi: msg.sender,
            Name: _name,
            Post: _post,
            age: _age,
            isregistered: true,
            noofvotes: 0
        });
        TotalCandidates++;
        RemainingSeats -= 1;
    }
    function castVote(address _Member) public 
    {
        require(msg.sender!=EC,"EC are not able to cast vote");
        require(deadline>block.timestamp,"Time Up");
        require(voters[msg.sender].voted,"You are not registered");
        Candidate storage thisvote = candidates[_Member];
        thisvote.noofvotes++;
        voters[msg.sender].voted = false; //problem is that,here voter unregistered and now the same person who voted, again able to register or cast vote
    }
}