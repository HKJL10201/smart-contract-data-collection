pragma solidity ^0.6.2;

import "https://github.com/smartcontractkit/chainlink/blob/develop/evm-contracts/src/v0.6/VRFConsumerBase.sol";
import "./Lottery.sol";

contract RandomNumberGenerator is VRFConsumerBase {

    address requester;
    bytes32 keyHash;
    uint256 fee;

    constructor(address _vrfCoordinator, address _link, bytes32 _keyHash, uint256 _fee)
        VRFConsumerBase(_vrfCoordinator, _link) public {
            keyHash = _keyHash;
            fee = _fee;
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        Lottery(requester).numberDrawn(_requestId, _randomness);
    }

    function request(uint256 _seed) public returns(bytes32 requestId) {
        require(keyHash != bytes32(0), "Must have valid key hash");
        requester = msg.sender;
        return super.requestRandomness(keyHash, fee, _seed);
    }
}


