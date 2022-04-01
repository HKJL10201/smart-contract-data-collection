pragma solidity ^0.8.0;

// SPDX-License-Identifier: AGPL-3.0-only
// Author: https://github.com/ankurdaharwal

import "./interfaces/LinkTokenInterface.sol";
import "./VRFConsumerBase.sol";
import "./Lottery.sol";

/// @title Random Number Generator
/// @author Ankur Daharwal (https://github.com/ankurdaharwal)
/// @notice Generates a random number based on the ChainLink VRF consumer implementation (https://docs.chain.link/docs/get-a-random-number/)
/// @dev Inherits VRFConsumerBase (ChainLink VRF)

// Reference ChainLink VRF: https://docs.chain.link/docs/get-a-random-number/

contract RandomNumberGenerator is VRFConsumerBase {

    address requester;
    bytes32 keyHash;
    uint256 fee;

    constructor(address _vrfCoordinator, address _link, bytes32 _keyHash, uint256 _fee)
        VRFConsumerBase(_vrfCoordinator, _link) {
            keyHash = _keyHash;
            fee = _fee;
    }

    /// @dev Fulfills a verifiable random number request and overrides the VRFConsumerBase parent contract function `fulfillRandomness`
    /// @param _requestId Unique request identifier
    /// @param _randomness Verifiable random number
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        Lottery(requester).numberDrawn(_requestId, _randomness);
    }
    
    /// @dev Requests a new verifiable random number
    /// @return requestId
    /// @param requestId Returns the unique requested random number identifier
    function request() public returns(bytes32 requestId) {
        require(keyHash != bytes32(0), "Must have valid key hash");
        requester = msg.sender;
        return this.requestRandomness(keyHash, fee);
    }
}