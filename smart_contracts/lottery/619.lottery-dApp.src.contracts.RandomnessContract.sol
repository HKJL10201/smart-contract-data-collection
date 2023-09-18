// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.8.0;

import "@chainlink/contracts/contracts/v0.6/VRFConsumerBase.sol";

import { ILotteryContract } from "./interfaces/ILotteryContract.sol";
import { IGovernanceContract } from "./interfaces/IGovernanceContract.sol";

contract RandomnessContract is VRFConsumerBase {
    address payable admin;
    
    bytes32 public reqId;
    uint256 public generatedNumber;
    
    bytes32 internal keyHash;
    uint256 internal fee;
    
    IGovernanceContract public governance;

    
    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     */
    constructor(address _linkTokenAddress, address _governance)
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            // 0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
            _linkTokenAddress
        ) public
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK
        admin = msg.sender;
        governance = IGovernanceContract(_governance);
    }

    function randomNumber(uint256 userProvidedSeed) public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee, userProvidedSeed);
    }
    
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        reqId = requestId;
        generatedNumber = randomness;

        // call lottery method and pass the random number
        ILotteryContract(governance.lottery()).fulfillRandomNumber(generatedNumber);
    }
    
    function getLINKBalance() public view returns (uint) {
        return LINK.balanceOf(address(this));
    }
}
