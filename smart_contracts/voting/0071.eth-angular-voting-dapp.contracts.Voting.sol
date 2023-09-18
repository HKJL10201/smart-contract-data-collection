// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Voting {

    struct Campaign {
        string name;
        uint256 candidateCounter;
    }

    struct Candidate {
        string name;
        uint256 voteCount;
    }

    // MODIFIERS

    modifier _campaignIndexExists(uint256 campaignId) {
        require(
            campaigns.length > campaignId,
            "Campaign with this index not exists."
        );
        _;
    }

    // EVENTS
    event CampaignCreatedEvent(string name, uint256 campaignIndex);
    event CandidateInCampaignCreated(
        uint256 campaignIndex,
        string candidateName,
        uint256 candidateIndex
    );

    // PRIVATE FIELDS
    Campaign[] campaigns;
    mapping(uint256 => Candidate[]) candidatesInCampaign;

    // HELPERS
    mapping(string => bool) usedCampaignNames;
    mapping(uint256 => mapping(address => bool)) votersInCampaign;

    mapping(uint256 => mapping(string => bool)) usedCandidateNamesInCampaign;

    // PUBLIC VIEW FUNCTIONS
    function getCampaignCount() public view returns (uint256) {
        return campaigns.length;
    }

    function getCampaignNameByIndex(uint256 campaignId)
        public
        view
        returns (string memory)
    {
        require(
            campaigns.length > campaignId,
            "Campaign with this index not exists."
        );
        return campaigns[campaignId].name;
    }

    function getCandidatesCountByCampaignId(uint256 campaignId)
        public
        view
        _campaignIndexExists(campaignId)
        returns (uint256)
    {
        return candidatesInCampaign[campaignId].length;
    }

    // PUBLIC MOD FUNCTIONS

    function addCampaign(string memory campaignName) public {
        require(
            !usedCampaignNames[campaignName],
            "This campaign name was already registered."
        );

        // Add campaign to array
        Campaign memory temp = Campaign(campaignName, 0);
        campaigns.push(temp);

        // add usedCampaignsNames
        usedCampaignNames[campaignName] = true;

        // emit event
        emit CampaignCreatedEvent(campaignName, campaigns.length - 1);
    }

    function addCandidateToCampaign(
        uint256 campaignIndex,
        string memory candidateName
    ) public _campaignIndexExists(campaignIndex) {
        require(
            usedCandidateNamesInCampaign[campaignIndex][candidateName],
            "This candidate name was already registered in this campaign."
        );

        // Add candidate to campaign
        Candidate memory temp = Candidate(candidateName, 0);
        candidatesInCampaign[campaignIndex].push(temp);

        // TODO: continue implementation
    }
}
