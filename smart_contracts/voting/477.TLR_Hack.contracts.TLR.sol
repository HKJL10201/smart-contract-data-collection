pragma solidity ^0.5.0;


contract TLRToken {
    uint public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals =18;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    //this mapping keeps track which addresses have allowed whom to spend money from their wallets
    
    event Transfer(address indexed _from,address indexed _to,uint tokens);
    event Approval(address indexed _tokenOwner,address indexed _spender,uint tokens);
    event Burn(address indexed _from,uint _value);
    
    
    constructor() public {
  
        name="TLRToken";
        symbol="TLR";
  
    }
    
    function _transfer(address _from,address _to,uint _value) internal {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from,_to,_value);
    }
    
    function transfer(address _to,uint _value) public returns(bool) {
        _transfer(msg.sender,_to,_value);
        return true;
    }
    
    function transferFrom(address _from,address _to,uint _value) public returns(bool) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from,_to,_value);
        return true;
    }
    
    function approve(address _spender,uint _value) public returns(bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
        
    }
}

contract TLR is TLRToken {
    
    address public deployer;
    
    uint public rewardValue;

    constructor(uint _initialSupply) public {
    totalSupply = _initialSupply*10**uint256(decimals);
    balanceOf[msg.sender] = _initialSupply;
    deployer = msg.sender;
    rewardValue=2;
        
    }
    
    uint public noOfReports;
    uint public noOfUsers;    
    struct Report{
        address payable Reporter;
        uint latitude;
        uint longitude;
        string message;
        uint votes;
        bool helped;
    }
 
    //keep track of all the reports by a particular user
    //mapping(address => mapping(uint=>Report)) public ReportHub;



    mapping(uint => Report) public Reports;



    //event that will emit data on adding new report
    event newReport(address indexed reporter,uint latitude,uint longitude,string message);
    
    event markedHelpful(uint indexed reportId,uint latitude,uint longitude,string message);
    
    
     //add report to ReportHub
    function addReport(uint _latitude, uint _longitude,string memory message) public {
        
        noOfReports+=1;

        if(Reports[noOfReports].Reporter==address(0)) { noOfUsers+=1; }
        else { }
    
    
        Reports[noOfReports]=Report(msg.sender,_latitude,_longitude,message,0,false);
        
        emit newReport(msg.sender,_latitude,_longitude,message);
        
    }

    //marks the report as helpful

    function voteReport(uint _reportId) public {

        Reports[_reportId].votes+=1;
    
    }

    
    function markHelpful(uint _reportId) public {

        require(msg.sender==deployer);

        //if more than 50% of active users, votes for a Report, then mark it as helped 
        require(Reports[_reportId].votes>noOfUsers/2);

        Reports[_reportId].helped=true;

        giveIncentive(Reports[_reportId].Reporter);

        emit markedHelpful(_reportId,Reports[_reportId].latitude,Reports[_reportId].longitude,Reports[_reportId].message);

    }
    
    
    
    //incentivizing the users if the report has helped to solve the crime
    function giveIncentive(address _hero) public {
    
        transfer(_hero,rewardValue);

    }

    
}