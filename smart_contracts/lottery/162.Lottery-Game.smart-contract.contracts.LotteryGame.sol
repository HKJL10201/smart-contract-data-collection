// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract LotteryGame is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;
  uint64 s_subscriptionId;
  bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
  uint32 callbackGasLimit = 100000;
  uint16 requestConfirmations = 3;
  uint32 numWords =  2;
  uint public randNumber;
  uint256 public s_requestId;
  
  address public owner;
  bool public startGame;
  uint public countPlayer;
  uint public countPlayerBetting;
  uint public rate;
  uint public fee;
  enum Status { PENDING, WIN, LOSE }

  struct Player {
    address account;
    uint luckyNUmber;
    uint bet;
    Status status;
  }

  mapping(uint => Player) public players;

  modifier onlyOwner(){
    require(msg.sender == owner, "Only owner");
    _;
  }

  event Betted(
    uint id,
    uint luckyNUmber,
    uint bet,
    address player
  );
  
  event RandomSuccess(
    uint number
  );

  constructor(uint64 _subscriptionId, address _vrfCoordinator) VRFConsumerBaseV2(_vrfCoordinator) {
    owner = msg.sender;
    rate = 2;
    fee = 10;
    COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    s_subscriptionId = _subscriptionId;
  }

  function bet(uint _luckyNumber) public payable {
    require(_luckyNumber >= 0 && _luckyNumber < 100, "Lucky number must be from 0 to 99");
    require(msg.value > 0, "Your bet must be greater than zero");
    countPlayer++;
    countPlayerBetting++;
    players[countPlayer] = Player(msg.sender, _luckyNumber, msg.value, Status.PENDING);
    emit Betted(countPlayer, _luckyNumber, msg.value, msg.sender);
  }

  function Gameover() public onlyOwner {
    startGame = false;
  }

  function getRandomNumber() public onlyOwner {
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }

  function fulfillRandomWords(
    uint256,
    uint256[] memory randomWords
  ) internal override {
    randNumber = randomWords[0] % 100;
    emit RandomSuccess(randNumber);
  }

  function updatePlayers() public payable onlyOwner {
    for(uint count = 1; count <= countPlayer; count ++)
    {
      Player storage player = players[count];
      
      if (player.luckyNUmber == randNumber) {
        player.status = Status.WIN;
        uint prize = (player.bet * rate) - fee;

        (bool sentWinner, ) = payable(player.account).call{value: prize}("");
        require(sentWinner, "Failed to send Ether");

        (bool sentOwner, ) = payable(owner).call{value: fee}("");
        require(sentOwner, "Failed to send2 Ether");
      } else {
        player.status = Status.LOSE;
      }
    }
    startGame = true;
    countPlayerBetting = 0;
  }
}