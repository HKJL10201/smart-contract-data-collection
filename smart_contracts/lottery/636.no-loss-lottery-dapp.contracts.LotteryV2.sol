//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/**@title Contract UpDate for No loss Lottery Dapp
  *@author ljrr3045
  *@notice This contract is version 2, to update the No loss Lottery Dapp project.
  *@dev Used to instantiate contract update.
*/

import "./LotteryV1.sol";

contract LotteryV2 is LotteryV1{

    ///@dev Function to confirm if the contract has been updated (only returns true).
    function upDate() public pure returns(bool){
        return true;
    }
}