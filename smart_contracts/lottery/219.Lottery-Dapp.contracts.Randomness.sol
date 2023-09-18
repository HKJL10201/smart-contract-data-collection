pragma solidity ^0.6.5;

import "https://raw.githubusercontent.com/smartcontractkit/chainlink/master/evm-contracts/src/v0.6/VRFConsumerBase.sol";
import {LotteryInterface} from "./LotteryInterface.sol";

contract Randomness is VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 seed;
    address lotteryContractAddress;
    address contractCreator;
    bool oneTime;

    //Kovan network
    constructor()
        public
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088 // LINK Token
        )
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10**18; // 0.1 LINK
        contractCreator = msg.sender;
    }

    //Can only be called once
    function lotteryAddress(address _adr) public {
        assert(oneTime == false);
        require(msg.sender == contractCreator, "Access Denied!");
        oneTime = true;
        lotteryContractAddress = _adr;
    }

    function getRandomNumber() external returns (bytes32 requestId) {
        //only lottery contract can call this function
        require(msg.sender == lotteryContractAddress, "Access Denied");
        require(LINK.balanceOf(address(this)) > fee, "Not enough LINK");
        seed++;
        return requestRandomness(keyHash, fee, seed);
    }

    function fulfillRandomness(bytes32 requestId, uint256 _randomNumber)
        internal
        override
    {
        //only VRF Coordinator can call this function
        require(
            msg.sender == 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9,
            "Access Denied!"
        );
        LotteryInterface(lotteryContractAddress).finalizeRound(_randomNumber);
    }
}
