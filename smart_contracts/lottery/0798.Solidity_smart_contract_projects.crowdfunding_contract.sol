// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract crowdfunding{
    mapping(address=>uint) public contributors;
    address public manager;
    uint public minmumcontribution;
    uint public deadline;
    uint public target;
    uint public raisedamount;
    uint public noofcontributors;

    struct request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noofvoters;
        mapping(address=>bool) voters;
    }

    mapping(uint=>request) public requests;
    uint public numrequests;

    constructor(uint _target, uint _deadline){
        target=_target;
        deadline=block.timestamp+_deadline; // imagine contract create on 100 sec then add deadline 20sec which means deadline is 120sec.
        minmumcontribution= 100 wei;
        manager=msg.sender;
    }

    function getether() public payable{
        require(block.timestamp<deadline,"deadline passed");
        require(msg.value>=minmumcontribution,"not enough ether");
        
        if(contributors[msg.sender]==0){ // if eth is 0 right now then increase the no of contributors. 
           noofcontributors++; 
        }
        
        contributors[msg.sender]+=msg.value;
        raisedamount+=msg.value;    
    }

    function showether() public view returns(uint){
        return address(this).balance;
    }

    function refund() public {
        require(block.timestamp>deadline && raisedamount < target);
        require(contributors[msg.sender]>0,"you are not elidgible");

        address payable user= payable(msg.sender);
        user.transfer(contributors[msg.sender]); //it is having ether.
        contributors[msg.sender]=0;
    }

    modifier onlymanager() {
        require(msg.sender==manager,"only manager can access this function.");
        _;
    }

    function createrequest(string memory _description, address payable _recipient, uint _value) public onlymanager{
        request storage newrequest= requests[numrequests];
        numrequests++;
        newrequest.description=_description;
        newrequest.recipient=_recipient;
        newrequest.value=_value;
        newrequest.completed= false;
        newrequest.noofvoters=0;
    }

    function voterequest(uint _requestno) public {
        require(contributors[msg.sender]>0,"you must be contributor.");
        request storage thisrequest=requests[_requestno];
        require(thisrequest.voters[msg.sender]==false,"you already voted");

        thisrequest.voters[msg.sender]== true;
        thisrequest.noofvoters++;
    }

    function makepayment(uint _requestno) public onlymanager{
        require(raisedamount>=target);
        request storage  thisrequest=requests[_requestno];
        require(thisrequest.completed==false);
        require(thisrequest.noofvoters>noofcontributors/2);
        thisrequest.recipient.transfer(thisrequest.value);
        thisrequest.completed=true;
    }

    




}