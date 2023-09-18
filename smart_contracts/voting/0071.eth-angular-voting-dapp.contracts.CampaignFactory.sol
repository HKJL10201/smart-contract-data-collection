// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

import "./Campaign.sol";

contract CampaignFactory {
  Campaign[] campaigns;
  mapping(string => bool) isCampaignExists;
  mapping(address => bool) isAddressExists;

  event CampaignCreated(address, string);

  function createCampaign(string memory campaignName) public {
    require(bytes(campaignName).length > 0 && !isCampaignExists[campaignName]);

    Campaign campaign = new Campaign(campaignName, msg.sender);
    campaigns.push(campaign);
    isCampaignExists[campaignName] = true;
    isAddressExists[address(campaign)] = true;
    emit CampaignCreated(address(campaign), campaignName);
  }

  function getCampaigns() public view returns (
    address[] memory _addressesArray,
    uint[] memory _voteCountsArray,
    bool[] memory _hasCandidatesArray,
    bool[] memory _canVoteArray,
    bool[] memory _isActiveArray,
    bool[] memory _isUserOwnerArray)
  {
    address[] memory _addresses = new address[](campaigns.length);
    string [] memory _names = new string[](campaigns.length);
    uint[] memory _voteCounters = new uint[](campaigns.length);
    bool[] memory _anyCandidates = new bool[](campaigns.length);
    bool[] memory _canVote = new bool[](campaigns.length);
    bool[] memory _isActive = new bool[](campaigns.length);
    bool[] memory _userIsOwner = new bool[](campaigns.length);

    for (uint i = 0; i < campaigns.length; i++) {
      address[] memory candidatesArray;

      (_names[i], _voteCounters[i], _canVote[i], candidatesArray, _isActive[i], _userIsOwner[i]) = campaigns[i].getCampaignInfo(msg.sender);
      _addresses[i] = address(campaigns[i]);
      _anyCandidates[i] = candidatesArray.length > 0;
    }
    //  TODO: add string[] with names to return values

    return (_addresses, _voteCounters, _anyCandidates, _canVote, _isActive, _userIsOwner);
  }

  function getCampaignName(address campaignAddress) external view returns (string memory) {
    require(isAddressExists[campaignAddress]);
    return Campaign(campaignAddress).getName();
  }

}
