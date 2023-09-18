// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Lottery is VRFConsumerBaseV2 {

  address owner; 
  uint8[] public rangeArray;
  uint8[] public winningArray;
  uint128 public ticketId;

  uint8[6][] public ticketsArray;
  address[] public ticketOwnersArray;

  address payable[] public sixWinners;
  address payable[] public fiveWinners;
  address payable[] public fourWinners;
  address payable[] public threeWinners;

  uint256 public ticketPrice;
  uint256 public prizePool;
  uint256 public protocolFee;

  uint256 threePrize;
  uint256 fourPrize;
  uint256 fivePrize;
  uint256 sixPrize;


  // CHAINLINK CONFIGURATION
  // xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

  VRFCoordinatorV2Interface COORDINATOR;

  // polygon mumbai
  address constant vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
  bytes32 constant keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

  uint64 immutable subscriptionId;
  uint32 constant callbackGasLimit = 2000000;
  uint16 constant requestConfirmations = 3;
  uint16 constant randomNumbersAmount =  6;
  uint256 public requestId;
  // xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx


  event WinningArraySet(uint8[] array);
  event UpdatePrizePool(uint256 updatedPrizePool);


  constructor(
    uint64 _subscriptionId
  ) VRFConsumerBaseV2(vrfCoordinator) {

    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    subscriptionId = _subscriptionId;

    owner = msg.sender;

    rangeArray = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36];
    ticketId = 0;

    // later set it to 1 ether
    ticketPrice = 10000000000000000; // 0.01 ether

    // set prizes:
    // later set: 1.2 ether
    threePrize = 12000000000000000; // 0.012 ether

    // later set: 5 ether
    fourPrize = 50000000000000000; // 0.05 ether

    // later set: 10 ether
    fivePrize = 100000000000000000; // 0.10 ether

  }



  // ===================================================
  //                  INTERNAL INTERFACE
  // ===================================================


  // get number from rangeArray and push to winningArray
  // after the is pushed to winningArray, delete it from the rangeArray 
  // so all the numbers are uniqe
  function getNumber(uint256 number) internal {
    winningArray.push(rangeArray[number]);

    delete rangeArray[number];

    for(uint256 i = number; i < rangeArray.length - 1; i++) {
      rangeArray[i] = rangeArray[i + 1];
    }
  }

  // pass here array of random numbers from chainlink to receive 
  // winningArray of 6 random numbers
  function setWinningArray(uint256[] memory randomNumbers) internal {

    getNumber(randomNumbers[0] % rangeArray.length);
    getNumber(randomNumbers[1] % rangeArray.length);
    getNumber(randomNumbers[2] % rangeArray.length);
    getNumber(randomNumbers[3] % rangeArray.length);
    getNumber(randomNumbers[4] % rangeArray.length);
    getNumber(randomNumbers[5] % rangeArray.length);

    emit WinningArraySet(winningArray);
  }

  // call to pay rewards to winners
  function payRewards(address payable withdrawTo, uint256 amount) internal {
    withdrawTo.transfer(amount);
  }

  // chainlink fallback distribute rewards
  function distributeRewardToWinners() internal {

    for(uint32 i = 0; i < threeWinners.length; i++) {
      payRewards(threeWinners[i], threePrize);
    }
    // update prize pool - subtract rewards for three
    prizePool = prizePool - (threeWinners.length * threePrize);


    for(uint32 i = 0; i < fourWinners.length; i++) {
      payRewards(fourWinners[i], fourPrize);
      prizePool = prizePool - fourPrize;
    }
    // update prize pool - subtract rewards for four
    prizePool = prizePool - (fourWinners.length * fourPrize);


    for(uint32 i = 0; i < fiveWinners.length; i++) {
      payRewards(fiveWinners[i], fivePrize);
    }
    // update prize pool - subtract rewards for five
    prizePool = prizePool - (fiveWinners.length * fivePrize);

    if(sixWinners.length != 0) {
      sixPrize = prizePool / sixWinners.length;
    }
    for(uint32 i = 0; i < sixWinners.length; i++) {
      payRewards(sixWinners[i], sixPrize);
    }
    // update prize pool - subtract rewards for four
    prizePool = prizePool - (sixWinners.length * sixPrize);

  }

  // admin check for winners and push them to arrays eligible for rewards
  // *** ONLY OWNER ***
  function checkWinners() internal {

    for(uint32 i = 0; i < ticketsArray.length; i++) {
      uint8 matching = 0;

      for(uint8 j = 0; j < ticketsArray[i].length; j++) {

        for(uint8 k = 0; k < winningArray.length; k++) {
          if(winningArray[k] == ticketsArray[i][j]) {
            matching = matching + 1;
          }
        }
      }

      if(matching == 6) {
        sixWinners.push(payable(ticketOwnersArray[i]));
      } else if(matching == 5) {
        fiveWinners.push(payable(ticketOwnersArray[i]));
      } else if(matching == 4) {
        fourWinners.push(payable(ticketOwnersArray[i]));
      } else if(matching == 3) { 
        threeWinners.push(payable(ticketOwnersArray[i]));
      }
    }
  }



  // ===================================================
  //                  PUBLIC INTERFACE
  // ===================================================

  // *** PAY TICKET PRICE ***
  function buyTicket(
    uint8 first,
    uint8 second,
    uint8 third,
    uint8 fourth,
    uint8 fifth,
    uint8 sixth
  ) public payable payTicketPrice {

    // 80% from the ticket price go to prizePool
    prizePool = prizePool + (msg.value / 100) * 80;
    // 20% from the ticket price go to protocolFee and is claimable by admin.
    protocolFee = protocolFee + (msg.value / 100) * 20;

    ticketsArray.push([first, second, third, fourth, fifth, sixth]);
    ticketOwnersArray.push(msg.sender);

    ticketId++; 

    emit UpdatePrizePool(prizePool);
  }



  // ===================================================
  //                  ADMIN INTERFACE
  // ===================================================

  // admin can restart the game
  // *** ONLY OWNER ***
  function resetGame() public {

    rangeArray = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36];
    ticketId = 0;

    delete ticketsArray;
    delete ticketOwnersArray;
    delete winningArray;

    delete sixWinners;
    delete fiveWinners;
    delete fourWinners;
    delete threeWinners;
  }




  // admin fund prize pool
  // *** ONLY OWNER ***
  function adminFundProtocol() public payable {
    prizePool = prizePool + msg.value;

    emit UpdatePrizePool(prizePool);
  }


  // adming withdraw fees
  // *** ONLY OWNER ***
  function adminWithdrawFees(address payable withdrawTo, uint256 amount) public onlyOwner {
    require(amount <= protocolFee, "Cannot withdraw more than protocol fee");

    protocolFee = protocolFee - amount;
    withdrawTo.transfer(amount);
  }


  // admin withdrawn all - helper - will be deleted
  // *** ONLY OWNER ***
  function adminWithdrawAll(address payable withdrawTo) public onlyOwner {
    withdrawTo.transfer(address(this).balance);
  }


  // START LOTTERY
  // xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

  // *** ONLY OWNER ***
  function startLottery() public {

    requestId = COORDINATOR.requestRandomWords(
      keyHash,
      subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      randomNumbersAmount
    );

    // assing requestId to gameId 
  }
  // xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx



  // ===================================================
  //               CHAINLINK FALLBACK
  // ===================================================

  // chainlink retrives random numbers here
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomNumbers) internal override {

    setWinningArray(_randomNumbers);

    checkWinners();
    distributeRewardToWinners();
  }



  // ===================================================
  //               MODIFIERS - REQUIREMENTS
  // ===================================================


  // Only owner is allowed to call function
  modifier onlyOwner() {
    require(msg.sender == owner, "You are not an owner");
    _;
  }


  // User must pay lottery ticket price
  modifier payTicketPrice() {
    require(msg.value == ticketPrice, "Incorrect value");
    _;
  }










}