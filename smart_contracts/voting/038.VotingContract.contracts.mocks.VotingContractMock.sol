// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../VotingContract.sol";

import "@artman325/community/contracts/interfaces/ICommunity.sol";

contract VotingContractMock is VotingContract {
   
    function setCommunityFraction(uint8 _communityRole, uint256 _communityFraction) public {
        
        for (uint256 i=0; i<voteData.communitySettings.length; i++) {
            
            if (
                voteData.communitySettings[i].communityRole == _communityRole
            ) {
                voteData.communitySettings[i].communityFraction  =_communityFraction;
            }
        }
        
    }
    
}