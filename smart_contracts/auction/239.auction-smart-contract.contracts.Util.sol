// SPDX-License-Identifier: ISC
pragma solidity ^0.7.4;

library Util {

    function etherToWei(uint sumInEth) public pure returns(uint) {
        return sumInEth * 1 ether;
    }

    function minutesToSeconds(uint timeInMin) public pure returns(uint) {
        return timeInMin * 1 minutes;  // na blockchain grava o tempo em segundos
    }
}