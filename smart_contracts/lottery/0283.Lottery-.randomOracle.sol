pragma solidity ^0.8.7;

// https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/vrf/VRFConsumerBase.sol
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBase.sol";//Library chainlink get random number from Oracle source 

contract RandomNumLottery is VRFConsumerBase {

/**
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
*/
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public Result;

    constructor() 
        VRFConsumerBase(
            0x271682DEB8C4E0901D1a1550aD2e64D568E69909, // VRF Coordinator Ethereum mainnet - https://docs.chain.link/vrf/v2/subscription/supported-networks
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token Ethereum mainnet - https://docs.chain.link/vrf/v2/subscription/supported-networks
        )
    {
        keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef; // Ethrereum mainnet
        fee = 0.25 * 10 ** 18; // 0.25 LINK (Varies by network)
    }

    function LotteryRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        Result = randomness;
    }

    // function withdrawLink() external {} - Implement a withdraw function to avoid locking your LINK in the contract
}