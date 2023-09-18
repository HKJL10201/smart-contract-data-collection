// SPDX-License-Identifier: MIT

// ChainLink random number

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

pragma solidity ^0.8.11;

contract Lottery is VRFConsumerBase {

    // owner of contract
    address public owner;

    // list of players (array)
    // payable = they can receive ether
    address payable[] public players;

    // lottery id
    uint public lotteryId;

    // winners
    mapping(uint => address payable) public lotteryHistory;


    // identifies which Chainlink Oracle to use.
    bytes32 internal keyHash;
    // invoking functions from chainlink requires LINK -> chainlink token.
    uint internal fee;
    // holds the random number which we are generating
    uint public randomResult;


    constructor()
      VRFConsumerBase(
          0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator, varifies that its truly a random number
          0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // address of LINK token on Rinkeby
        ){
          keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
          fee = 0.1 * 10 ** 18; // this is 0.1 LINK

          owner = msg.sender;
          lotteryId = 1;
        }


    // get random number
    function getRandomNumber() public returns(bytes32 requestId){
      // make sure you have enough LINK
      require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK in contract");
      return requestRandomness(keyHash, fee);
    }

    // fullfil randomness
    function fulfillRandomness(bytes32 requestId, uint randomness) internal override {
      randomResult = randomness; // mod gives nums from 0-9 // add1 to make sure its positive.
      payWinner();
    }

    // FUNCTIONS

    function getWinnerByLottery(uint lottery) public view returns(address payable){
        return lotteryHistory[lottery];
    }

    // get balance
    function getBalance() public view returns(uint){
        // returns how much is payed in this contract!
        return address(this).balance;
    }

    // get players
    function getPlayers() public view returns(address payable[] memory){
        return players;
    }

    // player enters lottery
    function enter() public payable {
        // player must pay to enter the lottery
        require(msg.value > .01 ether);
        // players are added to lottery
        players.push(payable(msg.sender));
    }


    // just owner can call this function
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    // pic winner
    function pickWinner() public onlyOwner{
        getRandomNumber();
    }

    function payWinner() public {
      uint index = randomResult % players.length;
      // pay to the winner
      players[index].transfer(address(this).balance);

      // add player to winners
      lotteryHistory[lotteryId] = players[index];

      // increment id of lottery
      // FIRST TRANSFER MONEY THAN CHANGE THE STATE
      // TO PREVENT REENTRY ATTACKS
      lotteryId++;

      // reset array for next round
      players = new address payable[](0);
    }


}
