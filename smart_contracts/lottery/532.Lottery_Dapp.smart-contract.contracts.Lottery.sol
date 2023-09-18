// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Lottery contract 
/// @author Glory Praise Emmanuel
/// @dev A contract that accepts collects money from people and gives the total to a person as a lottery

contract Lottery {

  address[] public playersRecord;
  address payable public winner;
  address public staff;
  uint256 public depositedMoney;

  event Deposite(uint256 amount, address indexed sender);
  event chooseWinner(address indexed selectedWinner);
  event moneyWon(uint amountWon);

  event noOfPlayer(uint256 totalPlayers);
  event lotteryBalance(uint256 currentLotteryBalance);


  constructor() {
    staff = msg.sender;
  }

  modifier onlyOwner {
    require(staff == msg.sender, "Denied, not a staff!");
    _;
  }

  
  function checkLotteryBalance() public returns (uint256) {

   emit lotteryBalance(address(this).balance);
   return address(this).balance;
  }

  function deposit() public payable {
    require(msg.value > 0, "You must have money t0 participate");
    require(msg.value >= 0.0001 ether , "You need to stake 0.0001 ethers to qualify for this lottery");
    depositedMoney += msg.value;
    // staff == msg.sender;
    // playersRecord.push(staff);
    // require(playersRecord[0] = staff, "The staff has to stake first to make the lottery fair, don't worry he isn't eligible to win");
    playersRecord.push(msg.sender);
    emit Deposite(msg.value, msg.sender);
  }

  function random() public view returns(uint256){
    return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
  }

  function pickWinner() public onlyOwner {
    require(playersRecord.length > 3, "3 players or more needed to pick a winner");

    uint r = random();
    uint256 calculate = r%playersRecord.length;
    winner = payable(playersRecord[calculate]);
    depositedMoney = checkLotteryBalance();
    winner.transfer(checkLotteryBalance());
    delete playersRecord;
    emit chooseWinner(winner);
  }

  function checkWinnerBalance()  public returns (uint256) {
   emit moneyWon(depositedMoney);
   return depositedMoney;
  }

  function checkNoOfPlayers() public returns(uint) {
    emit noOfPlayer(playersRecord.length);
    return playersRecord.length;
  }

}