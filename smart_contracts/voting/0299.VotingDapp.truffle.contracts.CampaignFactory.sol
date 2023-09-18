// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import './Campaign.sol';

contract CampaignFactory {

    Campaign[] public campaings;

    function createCampaign(uint _minimum) public {
        campaings.push(new Campaign(_minimum));
    }
}