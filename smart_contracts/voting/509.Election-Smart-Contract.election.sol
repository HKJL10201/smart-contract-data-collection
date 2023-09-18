//SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.9.0;

contract Election{

    struct vote{
        address voterAddress;
        string party;
    }

    struct voter{
        string voterName;
        bool voted ;
        string party;
    }

    uint public countVote=0;
    uint public countVoterRegistered=0;
    uint public countVotersVoted=0;
    uint public finalResult=0;
    string public winner="";

    mapping(string => uint) public votingBooth;
    mapping(address => voter) public voterRegister;
    
    enum State{created, voting, ended}
    State public state; 

    address public ElectionCommissionHeadAddress;
    string public ElectionCommissionHeadName;


    

    //modifier
    modifier inState(State _state){
        require(state == _state);
        _;
    }

    modifier onlyOfficials(){
        require(msg.sender == ElectionCommissionHeadAddress);
        _;
    }

    constructor(string memory _nameOfECHead, uint noOfParties, string[] memory parties)
    {
        ElectionCommissionHeadAddress = msg.sender;
        ElectionCommissionHeadName = _nameOfECHead;
        for(uint i=0;i<noOfParties;i++){
            votingBooth[parties[i]] =0;
            
        }
        
        state = State.created;
    }

    function addVoter(address addr, string memory name) public inState(State.created)
    {
        voter memory v;
        v.voterName = name;
        v.voted = false;
        voterRegister[addr] = v;
        countVoterRegistered++;
    }

    function votingStart() public onlyOfficials inState(State.created){
        state = State.voting;
    }

    function doVote(string memory partyElect) public inState(State.voting){

        if(bytes(voterRegister[msg.sender].voterName).length != 0 
        && voterRegister[msg.sender].voted == false)
        {
            votingBooth[partyElect]++;
            if(votingBooth[partyElect] > finalResult){
                finalResult = votingBooth[partyElect];
                winner = partyElect;
            }
            vote memory v1;
            v1.voterAddress = msg.sender;
            v1.party = partyElect;
            voter memory v2;
            v2.party = partyElect;
            v2.voted = true;
            voterRegister[msg.sender] = v2;
            countVote++;countVotersVoted++;
        }

    }

    function endVoting() public inState(State.voting) onlyOfficials
    {
        state = State.ended;
    }

    function Winner() public view inState(State.ended) returns(string memory){
        return winner;

    }
    

}