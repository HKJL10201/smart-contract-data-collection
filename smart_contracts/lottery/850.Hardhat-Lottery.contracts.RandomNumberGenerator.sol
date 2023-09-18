// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRandomNumberGenerator.sol";

error RandomNumberGenerator__CallFromUnapprovedContract();

contract RandomNumberGenerator is IRandomNumberGenerator, VRFConsumerBaseV2, Ownable {
    mapping(address => bool) private approvedContracts;
    mapping(uint256 => uint256) private requestIdToRandomWords;

    uint256 public requestId;

    VRFCoordinatorV2Interface public vrfCoordinator;
    bytes32 public keyHash;
    uint64 public subscriptionId;
    uint32 public callbackGasLimit = 1e6;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;

    event RandomWordsRequested(uint256 requestId);

    constructor(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
    }

    function isApprovedContract(address _contractAddress) public view returns (bool) {
        return approvedContracts[_contractAddress];
    }

    function setApprovedContract(address _contractAddress) public onlyOwner {
        approvedContracts[_contractAddress] = true;
    }

    function removeApprovedContract(address _contractAddress) public onlyOwner {
        approvedContracts[_contractAddress] = false;
    }

    function getRandomNumber(uint256 _requestId) public view override returns (uint256) {
        return requestIdToRandomWords[_requestId];
    }

    function requestRandomWords() public override returns (uint256) {
        if (!isApprovedContract(msg.sender)) {
            revert RandomNumberGenerator__CallFromUnapprovedContract();
        }
        requestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        emit RandomWordsRequested(requestId);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _numWords) internal override {
        requestIdToRandomWords[_requestId] = _numWords[0];
    }
}
