// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    address public admin;
    uint256 public campaignCount;

    struct Candidate {
        string name;
        uint256 voteCount;
    }

    struct Campaign {
        uint256 id;
        string name;
        uint256 startDate;
        uint256 endDate;
        bool isActive;
        address[] voterList;
        Candidate[] candidates;
        mapping(address => bool) hasVoted;
        mapping(address => uint256) candidateVoted;
    }

    mapping(uint256 => Campaign) public campaigns;
    mapping(address => bool) public isAdmin;

    constructor() {
        admin = msg.sender;
        isAdmin[admin] = true;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admin can call this function");
        _;
    }

    function createCampaign(
        string memory name,
        uint256 startDate,
        uint256 endDate,
        address[] memory voterList,
        string[] memory candidateNames
    ) public onlyAdmin {
        require(endDate > startDate, "End date must be after start date.");
        require(candidateNames.length > 0, "Candidate list cannot be empty.");
        require(voterList.length > 0, "Voter list cannot be empty.");

        campaignCount++;
        uint256 campaignId = campaignCount;

        Candidate[] storage candidates = campaigns[campaignId].candidates;
        for (uint256 i = 0; i < candidateNames.length; i++) {
            candidates.push(Candidate(candidateNames[i], 0));
        }

       
        Campaign storage newCampaign = campaigns[campaignId];
        newCampaign.id = campaignId;
        newCampaign.name = name;
        newCampaign.startDate = startDate;
        newCampaign.endDate = endDate;
        newCampaign.isActive = true;
        newCampaign.voterList = voterList;
    }

    function vote(uint256 campaignId, uint256 candidateId) public {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.isActive, "Campaign INACTIVE : Cannot Vote");
        require(block.timestamp >= campaign.startDate && block.timestamp <= campaign.endDate, "Voting has ended");
        require(!campaign.hasVoted[msg.sender], "You have already voted");
        require(campaign.candidates[candidateId].voteCount != 0, "Invalid candidate.");

        campaign.hasVoted[msg.sender] = true;
        campaign.candidateVoted[msg.sender] = candidateId;
        campaign.candidates[candidateId].voteCount++;
    }

    function endCampaign(uint256 campaignId) public onlyAdmin {
        require(campaigns[campaignId].isActive, "Campaign is not active.");
        campaigns[campaignId].isActive = false;
    }

    function getCandidates(uint256 campaignId) public view returns (Candidate[] memory) {
        Candidate[] storage candidates = campaigns[campaignId].candidates;
        Candidate[] memory candidateList = new Candidate[](candidates.length);

        for (uint256 i = 0; i < candidates.length; i++) {
            candidateList[i] = candidates[i];
        }

        return candidateList;
    }

    function getVoterList(uint256 campaignId) public view returns (address[] memory) {
        return campaigns[campaignId].voterList;
    }
}