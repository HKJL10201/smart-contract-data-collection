// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import './VotingStage.sol';

contract VotingDappDeployer {

    constructor() {}

   
    function deploy(address firstC, address secondC, address thirdParty) internal returns(address stage) {
        stage = address(new VotingStage(firstC, secondC, thirdParty));

    }


}

contract VotingDappFactory is VotingDappDeployer {
   // this will keep track of the total amount of times people have created votes. 
   uint256 public totalRounds;
   address public studio;
   uint public cost;


   mapping(address => mapping(address => address)) public canidateAddress;
   mapping(address => address) public canidateHistory;
   mapping(uint => address) public votingHistory;

   
   constructor() {
      studio = msg.sender; 
      cost = 0.5 ether;
      totalRounds = 0;
   }

   function createVote(
      address _firstC, 
      address _secondC,
      address _thirdParty
   ) payable public returns (address vote) {
      totalRounds++; 
      require(msg.value >= cost, 'Sorry you dont have enough ether');

      vote = deploy(_firstC, _secondC, _thirdParty);
      canidateHistory[_firstC] = vote;
      canidateHistory[_secondC] = vote;

      votingHistory[totalRounds] = vote;


   }

// * receive function
    receive() external payable {}

    // * fallback function
    fallback() external payable {}
}
