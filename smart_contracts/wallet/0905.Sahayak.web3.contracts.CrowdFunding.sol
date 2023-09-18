// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Building Smart Contract
contract CrowdFunding {
    struct Campaign{
        //created an object(called structure for javascript)

        //The types this campaign object will have:
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;   //we will insert an URL for image
        address[] donators; //array of addresses of donators
        uint256[] donations;
    } 
   
    mapping (uint256 => Campaign ) public campaigns;

    uint256 public numberOfCampaigns = 0; //global variable to keep track bumber of campaigns we have created
                                          //to be able to give them an id
   
   function createCampaign(address _owner, string memory _title, string memory _description, 
   uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {

    Campaign storage campaign = campaigns[numberOfCampaigns];

    //Check to see is everything okay? --> kinda like if statement in C++
    require(campaign.deadline < block.timestamp, "The deadline should be a date in the future.");
    
    //IF the above required condition if fullfilled--->
   
    //writing the varipus variables of the function
    campaign.owner = _owner;
    campaign.title = _title;
    campaign.description = _description;
    campaign.target = _target;
    campaign.deadline = _deadline;
    campaign.amountCollected = 0;
    campaign.image = _image;

    numberOfCampaigns++;

    return numberOfCampaigns - 1; //returns index of the most newly created campaign

   }

   function donateToCampaign(uint256 _id) public payable {
    //We take the id of the campaign that we want to donate to
    //We make it a public function so the client side can interact with it
    //We use a special keyword "payable" that signifies that we're gonna send some crypto throughout this function

    uint256 amount = msg.value; //this is what we are trying to send from our frontend
    
    //Getting the Campaign that i want to donate to
    Campaign storage campaign  = campaigns[_id];

    campaign.donators.push(msg.sender); //Stroing the donator name
    campaign.donations.push(amount);    //Storing the donated amount

    //Let's make the transaction
    (bool sent, ) = payable(campaign.owner).call{value: amount}("");

    if(sent){
        campaign.amountCollected = campaign.amountCollected + amount;
    }

   }

   function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) {
     
     //used (view) keyword because it allows only to view the function outputs
     
     //simply return the donators and their donations from the required 
     //id of the campaign
      return (campaigns[_id].donators, campaigns[_id].donations);
   }

   function getCampaigns() public view returns(Campaign[] memory) {
     
     Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns); 
     //the above statement basically created an emoty array of (numberOfCampaigns)
     //number of structs
     //basically it created ----> [{}, {}, {}, {}, .... numberOfCampaigns times]
     
     for(uint i=0; i<numberOfCampaigns; i++){
        Campaign storage item = campaigns[i];

        allCampaigns[i] = item;

     }

     return allCampaigns;
   }
}