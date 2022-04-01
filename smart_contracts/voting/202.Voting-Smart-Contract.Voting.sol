pragma solidity ^0.5.3;

contract voting {
    address public owner;
    address[] public participants;
    mapping (address => uint) public votes;

    address public winner;
    uint public winnervotes;

    constructor() public{
        owner =  msg.sender;
    }
    modifier OwnerOnly{
        if(msg.sender == owner){
            _;
        }
    }
    enum State{NotStarted,Ongoing,Completed}
    State public setStatus;

    function SetTheStatus()  OwnerOnly public{
        if(setStatus == State.NotStarted){
        setStatus = State.Ongoing;
        }
        else{
            setStatus= State.Completed;
            }
        }

    function register(address _candidate) public OwnerOnly{
        participants.push(_candidate);
    }

    function Validate(address _address) public view returns(bool){
    for(uint i=0;i<participants.length;i++){
        if(participants[i] == _address){
        return true;
        }
        }
        return false;
    }
    
    function Vote(address _address) public {
    require(Validate(_address),"Not a Valid Address");
    require(setStatus == State.Ongoing,"Wrong State");
    votes[_address]+=1;
    }

    function CheckCount(address _address) public view returns(uint){
       require(Validate(_address),"Not a Valid Address");
        require(setStatus == State.Ongoing,"Wrong State");
        return votes[_address];
    }

    
    function result() public{
         require(setStatus == State.Completed,"Wrong State");
        for(uint i=0;i<participants.length;i++){
            if(votes[participants[i]] > winnervotes){
            winnervotes = votes[participants[i]];
            winner = participants[i];
            }
            }
    }   
}