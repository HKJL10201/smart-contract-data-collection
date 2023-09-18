// SPDX-License-Identifier: MIT

// random number gathered with ChainLink

pragma solidity ^0.8.11;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract RandomNumber is VRFConsumerBase {

  // identifies which Chainlink Oracle to use.
  bytes32 internal keyHash;
  // invoking functions from chainlink requires LINK -> chainlink token.
  uint internal fee;
  // holds the random number which we are generating
  uint public randomResult;

  constructor()
    VRFConsumerBase(
        0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator, varifies that its truly a random number
        0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // address of LINK token on Rinkeby
      ){
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10 ** 18; // this is 0.1 LINK
      }


  // get random number
  function getRandomNumber() public returns(bytes32 requestId){
    // make sure you have enough LINK
    require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK in contract");
    return requestRandomness(keyHash, fee);
  }

  // fullfil randomness
  function fulfillRandomness(bytes32 requestId, uint randomness) internal override {
    randomResult = randomness.mod(10).add(1); // mod gives nums from 0-9 // add1 to make sure its positive.
  }


}
