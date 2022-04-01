//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2 ; 

// linter warnings (red underline) about pragma version can igonored!

// contract code will go here
contract deploymentContract {
    startupInfo[] public deployedCampaigns;
    
    function createCampaign(uint minimumAmount, uint fundGoals) public {
        startupInfo newCampaign = new startupInfo(minimumAmount, msg.sender, fundGoals) ;
        deployedCampaigns.push(newCampaign);
    }
    
    function getDeployedCampaigns() public view returns (startupInfo[] memory) {
        return deployedCampaigns;
    }
}

contract startupInfo{
    struct CompanyDetails{
        string nameOfCompany;
        string nameOfFounder;
        bool launchedMVP;
        bool incomeGenerating;
        uint numberOfEmployees;
        string reasonForRaise;
        string additionalInfo;
    
    }
    struct AllCompanies{
        address name;
        mapping(address => uint)  investors;
        uint totalRaised;
        uint totalCount;
    }
    mapping (address => AllCompanies) public each_company;
    struct RequestToSpendRaisedMoney{
        string description;
        uint value;
        address payable recipient;
        bool complete;
        uint8 approvalsCount;
        mapping(address => bool) approvedTheRequest;
      
    }
    //RequestToSpendRaisedMoney[] public requestFunds;
    mapping(uint => RequestToSpendRaisedMoney) public requestFunds;
    CompanyDetails[] public companyInfo;
    address public founder;
    uint public minCheckSize;
    mapping(address => uint) public contributors; // this is same as investors, it just allows us store investors and access it in the approveRequest function

    uint public fundingGoal;
    uint public numRequests; // keeps track of number of requests
  
    modifier restrictAccess(){
        require (msg.sender == founder);
        _;
    }
    //this function uses the struct created earlier to get the details of the company
   constructor  (uint minimumAmount, address founderAddress, uint fundGoals){
         require(fundGoals > minimumAmount, "Your funding goal should be more than the minimum amount"); // the funding goal must be greater than the minimum check size       
        //require(msg.sender == founder);
        //founder = msg.sender;
        minCheckSize =minimumAmount;
        fundingGoal= fundGoals; 
       founder = founderAddress;
   }
   
   function create_Company (string memory nameOfCompany, string memory nameOfFounder, bool  launchedMVP, bool incomeGenerating, uint numberOfEmployees, string memory reasonForRaise, string memory additionalInfo) public{
        CompanyDetails memory newDetails = CompanyDetails({
            nameOfCompany: nameOfCompany,
            nameOfFounder: nameOfFounder,
            launchedMVP: launchedMVP,
            incomeGenerating: incomeGenerating,
            numberOfEmployees: numberOfEmployees,
            reasonForRaise: reasonForRaise,
    
            additionalInfo: additionalInfo
        });
        companyInfo.push(newDetails);
        //founder = msg.sender;
        
    }

    function startUpFundingAmount(uint minimumAmount ,  uint fundGoals) public restrictAccess{
        require(fundGoals > minimumAmount, "Your funding goal should be more than the minimum amount"); // the funding goal must be greater than the minimum check size       
        //require(msg.sender == founder);
        //founder = msg.sender;
        minCheckSize =minimumAmount;
        fundingGoal= fundGoals ;

    }

    function contribute(address to) public payable{
        require(msg.value > minCheckSize, "Insufficient amount"); // ensures that the amount to be donated is more than the minimum amount
        require(to == founder); // ensures you dont send money to anyone not a founder
       contributors[msg.sender] = 1; //it gives the value of 1 to any address that calls this contribute function successfully
       each_company[to].totalRaised =each_company[to].totalRaised + msg.value; // how much has been raised
       each_company[to].investors[msg.sender]= msg.value;
       each_company[to].name = founder; // returns name of companu
       each_company[to].totalCount++; // this retrieves total people that have contributed to that company
       
    
    }
    
   
    function createWithdrawalRequest( string calldata description, uint value, address payable recipient) public restrictAccess{
      //gets the last indext of requests
      RequestToSpendRaisedMoney storage newRequest= requestFunds[numRequests];
      //increments the number of requests;
       numRequests++ ;
       newRequest.description=description;
       newRequest.value= value;
       newRequest.recipient= recipient;
      // newRequest.complete= false;
       newRequest.approvalsCount= 0;
         }
        //requestFunds.push(newRequest);
    
     
     function approveRequest (uint id) public {
        RequestToSpendRaisedMoney storage requests = requestFunds[id]; 
      
        require(!requests.approvedTheRequest[msg.sender]); // checks to ensure that the person has NOT voted on this request before
        require(contributors[msg.sender] >0); // checks that the adddress calling this function has sent money before
        requests.approvedTheRequest[msg.sender] = true; //this sets that if the investor calls this function to approve the request it is counted as true
        requests.approvalsCount++;

     }
     function finaliseRequest(uint id) public payable restrictAccess{
         RequestToSpendRaisedMoney storage requests = requestFunds[id];
        // AllMonies storage money =
         require(!requests.complete); // confirms that the transaction hasnt been completed before
         require(requests.approvalsCount> (each_company[founder].totalCount/2));
         requests.complete = true; 
         requests.recipient.transfer(requests.value);
        
     }
     
     
    }
 
    