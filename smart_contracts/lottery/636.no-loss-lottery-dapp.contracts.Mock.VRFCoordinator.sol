// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/**@title VRF Coordinator Mock
  *@author ljrr3045
  *@notice Contract used to replicate the ChainLink VRF Coordinator contract and thus be able to obtain 
  random numbers during the tests.
*/

import "@chainlink/contracts/src/v0.7/tests/VRFCoordinatorMock.sol";

contract VRFCoordinator is VRFCoordinatorMock {

    constructor(address linkAddress) VRFCoordinatorMock(linkAddress){}
}