// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import './VotingStage.sol';

contract VotingDappDeployer{

    constructor() {}

   
    function deploy(address firstC, address secondC, address thirdParty) internal returns(address vote) {
        vote = address(new VotingStage(firstC, secondC, thirdParty));

    }


}
