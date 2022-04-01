// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Election
{
    struct Candidate
    {
        string name;
        uint voteCount;
    }
    
    struct Voter
    {
        bool authorized;    //only authorized person can vote so True or false
        bool voted;     //have the person voted to stop double voting
        uint vote;  //to keep the track of the vote
    }
    
    //creation of state variables 
    
    address payable public ownerp;   //the address of the owner for the deploying
    address public owner;
    string public electionName;     //so that we can identify the elction with the name and give one
    
    mapping(address => Voter) public voters;
    
    Candidate[] public candidates;  //array of candidates
    
    uint public totalVotes; //count of total votes
    
    //creation of methods
    
    modifier ownerOnly()
    {
        require(msg.sender == owner);   //check input conditions so we used require
        _;  //underscore represent remaining body of the function
    }
    
    constructor(string memory _name) public
    {
        owner = msg.sender; //msg is one of the global variable in solidity msg.sender is the address of the account whoever deployed it.
        ownerp = payable(address(owner));
        electionName = _name;
    }
    
    function addCandidate(string memory _name) ownerOnly public
    {
        candidates.push(Candidate(_name, 0));
    }
    
    //we need view because we don't want to change any state
    function getNumCandidate() public view returns(uint)    
    {
        return candidates.length;
    }
    
    function authorize(address _person) ownerOnly public
    {
        voters[_person].authorized = true;
    }
    
    function vote(uint _voteIndex) public
    {
        require(!voters[msg.sender].voted);
        require(voters[msg.sender].authorized);
        
        voters[msg.sender].vote = _voteIndex;
        voters[msg.sender].voted = true;
        
        candidates[_voteIndex].voteCount += 1;
        totalVotes += 1;
    }
    
    function end() ownerOnly public
    {
        selfdestruct(ownerp);    //no state changes and ends the contarcts and remaining ethers will be passed to owner.
    }
}
