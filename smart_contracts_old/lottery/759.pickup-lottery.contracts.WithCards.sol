// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./v0.6/VRFConsumerBase.sol";

/**
    Playing Card

    01 ~ 13: Heart A - K
    14 ~ 26: Spade A - K
    27 ~ 39: Diamond A - K
    40 ~ 52: Club A - K
    53: Black Joker
    54: Red Joker
 */

contract WithCards is VRFConsumerBase {
    uint256[54] internal _cardsList;

    address private constant VRFCoordinator = address(0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9);
    address private constant LinkToken = address(0xa36085F69e2889c224210F603D836748e7dC0088);
    bytes32 internal keyHash;
    uint256 internal fee;

    modifier onlyValidCard(uint256 _card) {
        require(_card > 0 && _card < 55, "Card should be between 1 and 54");
        _;
    }

    constructor() VRFConsumerBase(VRFCoordinator, LinkToken) public {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    }

    // Request randomness
    function requestShuffle() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    // Callback used by VRF Coordinator
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 temp;
        uint256 pairId;
        // shuffle cards based on random number
        for (uint256 i = 0; i < 54; i++) {
            pairId = uint256(keccak256(abi.encode(randomness, i+1))).mod(54);
            if (pairId == i) {
                continue;
            }
            temp = _cardsList[i];
            _cardsList[i] = _cardsList[pairId];
            _cardsList[pairId] = temp;
        }
    }

    function initCardsList() internal {
        for (uint256 i; i<54; i++) {
            _cardsList[i] = i + 1;
        }
    }

    function generateCardsList() internal {
        initCardsList();
        requestShuffle();
    }
}