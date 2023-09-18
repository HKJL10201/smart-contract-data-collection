// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract VRFCoordinatorV2MockOverride is VRFCoordinatorV2Mock {
    constructor(
        uint96 _baseFee,
        uint96 _gasPriceLink
    ) VRFCoordinatorV2Mock(_baseFee, _gasPriceLink) {}

    function fulfillRandomWordsWithGivenWords(
        uint256 _requestId,
        address _consumer,
        uint256[] memory _words
    ) external {
        fulfillRandomWordsWithOverride(_requestId, _consumer, _words);
    }
}
