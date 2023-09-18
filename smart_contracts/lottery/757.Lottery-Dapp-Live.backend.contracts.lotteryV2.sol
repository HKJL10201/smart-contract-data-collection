// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract lotteryV2 is VRFConsumerBaseV2 {
    uint256 private constant ROLL_IN_PROGRESS = 100;

    event DiceRolled(uint256 indexed requestId, address indexed roller);
    event DiceLanded(uint256 indexed requestId, uint256 indexed result);

    VRFCoordinatorV2Interface COORDINATOR;
    address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;

    bytes32 s_keyHash =
        0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    uint64 s_subscriptionId;

    uint256 public result;

    uint256 public Lottery = 1;

    uint32 callbackGasLimit = 40000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    address s_owner;

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }

    // mapping(uint256 => address) public participants;
    address payable [] public participants;
    mapping(address => uint256) public requestIds;
    mapping(address => uint256) public results;
    mapping(uint256 => address) public request;

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
    }

    function openLottery() public returns (uint256 requestId) {
        require(result == 0,"Please wait for result");
        require(participants.length >= 10, "please wait for participant");
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        request[requestId] = msg.sender; //request id
        requestIds[msg.sender] = requestId;
        results[msg.sender] = ROLL_IN_PROGRESS;
        emit DiceRolled(requestId, msg.sender);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 d20Value = (randomWords[0] % 10)+1;
        result = d20Value;
        results[request[requestId]] = d20Value;
        emit DiceLanded(requestId, d20Value);
    }

    function participant() public payable {
    require(participants.length < 10 ,"please wait for second raound");
    require(msg.value > 5, "please send 5 Wei");
        participants.push(payable(msg.sender));
    }

    function sendToWinner() public onlyOwner {
        require(result != 0, "please Wait for result");
        (bool success,) = participants[result].call{
                value: address(this).balance
            }("");
            if (!success) {
                revert("transaction fails ");
            }
            result = 0;
            Lottery++;
            delete participants;
    }

    function getBalance() public view returns(uint256){
    return address(this).balance;        
    }

    function getparticipants() public view returns (address payable [] memory) {
        return participants;
    }

    //0x74591489042022d2977fe0587e4005a2Fd1521DB(deplyed contract)
}
