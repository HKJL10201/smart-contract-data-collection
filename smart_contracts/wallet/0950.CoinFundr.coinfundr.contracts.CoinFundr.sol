// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @title CoinFunder Smart Contract
/// @author Waleed H.
/// @notice Web 3.0 Crowdfunding Platform
/// @dev ...

// Defining Structure of Smart Contract & Data Types for each parameter

contract CoinFundr {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donors;
        uint256[] donations;
    }

    // Mapping parameters into 'campaigns' object

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;

    // Defining Campaign Creation Function

    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        // Is Everything OK?    
        require(campaign.deadline < block.timestamp, "The deadline should be a date in the future");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    // Defining Campaign Donation Function

    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donors.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent,) = payable(campaign.owner).call{value: amount}("");
        
        if(sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }
    
    // Defining Donor Retrieval Function

    function getDonors(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donors, campaigns[_id].donations);
    }

    // Defining Campaign Retrieval Function

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns  = new Campaign[](numberOfCampaigns);

        for(uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
    
}