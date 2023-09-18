// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract VotingStage {
    address public immutable firstCanidate;
    address public immutable secondCanidate;
    address public immutable thirdParty;


    constructor(address _firstC, address _secondC, address _thirdParty) {
        firstCanidate = _firstC; 
        secondCanidate = _secondC; 
        thirdParty = _thirdParty;
    }


}