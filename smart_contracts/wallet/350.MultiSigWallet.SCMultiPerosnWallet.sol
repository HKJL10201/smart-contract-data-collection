// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;


contract MultiPersonWallet {

    //Making the set of people 
    address[] public Participants;
    

    //the contract deployer and Mainman who is in charge
    address payable public bossman;  //deployer



    constructor(){
        bossman = payable(msg.sender);
    }

    mapping (address=>bool) owners;

    // adding a person to the wallet          //Works
    function addparticipant(address _participant) public {
        require(msg.sender == bossman, "Not BOSSMAN");
        Participants.push(_participant);
        owners[_participant] = true;      
    }

    

    modifier Owners{
        require( owners[msg.sender]);
        _;
    }

    //adding money and viewing the contract balance     //works
    function addMoney() public payable{}    

    function contractbalance() view public returns(uint){
       return address(this).balance;
    }



    //requests
    struct Requests {
        uint value;
        address payable recipient;
        string reason;
        uint votecount;
        bool Completed;
    }

    Requests[] public RequestsArray;
    //mapping (uint => Requests) public RequestsArray;

    //View current requests 

    //requesting to transfer money
    function request(uint _value,address payable _to, string memory _reason) public Owners {
     RequestsArray.push(Requests(_value, _to, _reason,0,false));

    }

    //vote 

    //struct AllVotes{
    //  address Voter;
    //  bool Voted;    
    //}
    modifier NoRequests{
        require( RequestsArray.length != 0, "No current Requests");
        _;
    }

    modifier RequestCompleted(uint _requestno){
        require(RequestsArray[_requestno].Completed == false,"Request Completed");
        _;
    }


    mapping(uint => mapping(address => bool)) votes;

    function vote(uint _requestno) public Owners NoRequests RequestCompleted(_requestno) {
        require(votes[_requestno][msg.sender] == false,"Already Voted");

        RequestsArray[_requestno].votecount += 1;
        votes[_requestno][msg.sender] = true;
    }

    //sending money form the contract
    function sendmoney(uint _requestno) public Owners NoRequests RequestCompleted(_requestno) payable{

        uint NumberofdecidingVotes = (Participants.length)/2;
        require(RequestsArray[_requestno].votecount > NumberofdecidingVotes,"Insufficient no of Votes");

        RequestsArray[_requestno].recipient.transfer(RequestsArray[_requestno].value);
        RequestsArray[_requestno].Completed = true;
    
    }

}