// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "hardhat/console.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Reviewer.sol";

contract VRFv2Consumer is VRFConsumerBaseV2, Ownable {
    VRFCoordinatorV2Interface COORDINATOR;

    struct Request {
        uint256 orgId;
        uint256 reviewId;
        uint256 requestId;
        uint256 randomWord;
        uint256 groupId;
        bool isConsumed; // has the random word been used?
    }

    address private s_reviewerAddr;
    uint64 private _s_subscriptionId;

    // Rinkeby coordinator
    // address private _vrfCoordinator =
    //     0x6168499c0cFfCaCD319c818142124B7A15E857ab;

    // The gas lane to use
    bytes32 keyHash =
        0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    mapping(uint256 => uint256) public s_assignedGroup; // requestId -> groupId
    mapping(uint256 => Request) public s_requests; // requestId -> [orgId, reviewId]

    // errors
    error VRFv2Consumer__OnlyReviewerContract();

    constructor(
        uint64 subscriptionId,
        address reviewerAddr_,
        address vrfCoordinator_
    ) VRFConsumerBaseV2(vrfCoordinator_) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator_);
        _s_subscriptionId = subscriptionId;
        s_reviewerAddr = reviewerAddr_;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords(uint256 orgId_, uint256 reviewId_) external {
        if (_msgSender() != s_reviewerAddr && _msgSender() != owner()) {
            revert VRFv2Consumer__OnlyReviewerContract();
        }
        // Will revert if subscription is not set and funded.
        uint256 _requestId = COORDINATOR.requestRandomWords(
            keyHash,
            _s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        Request memory _request = Request({
            orgId: orgId_,
            reviewId: reviewId_,
            requestId: _requestId,
            randomWord: 0,
            groupId: 0,
            isConsumed: false
        });
        s_requests[_requestId] = _request;
    }

    function setReviewerAddr(address reviewerAddr_) external onlyOwner {
        s_reviewerAddr = reviewerAddr_;
    }

    function fulfillRandomWords(
        uint256 requestId_,
        uint256[] memory randomWords
    ) internal override {
        uint256 _groupId = _convertToGroupId(randomWords[0]);
        Request memory _request = s_requests[requestId_]; // storage - to access by reference; memory - to create separate copy. Test gas diff in this case
        s_requests[requestId_].randomWord = randomWords[0];
        s_requests[requestId_].groupId = _groupId;
        _updateReviewGroupId(_request.orgId, _request.reviewId, _groupId);
    }

    function _updateReviewGroupId(
        uint256 orgId_,
        uint256 reviewId_,
        uint256 groupId_
    ) private {
        Reviewer reviewerContract = Reviewer(s_reviewerAddr);
        reviewerContract.updateReviewGroupId(orgId_, reviewId_, groupId_);
    }

    function _convertToGroupId(uint256 randomWord_)
        private
        pure
        returns (uint256)
    {
        uint256 _randomRange = (randomWord_ % 5) + 1;
        return _randomRange;
    }
}
