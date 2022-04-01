// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../VotingContract.sol";
import "../interfaces/ICommunity.sol";

contract VotingContractMock is VotingContract {
   
    function setCommunityFraction(string memory _communityRole, uint256 _communityFraction) public {
        
        for (uint256 i=0; i<voteData.communitySettings.length; i++) {
            
            if (
                keccak256(abi.encodePacked(voteData.communitySettings[i].communityRole)) == 
                keccak256(abi.encodePacked(_communityRole))
            ) {
                voteData.communitySettings[i].communityFraction  =_communityFraction;
            }
        }
        
    }
    
}