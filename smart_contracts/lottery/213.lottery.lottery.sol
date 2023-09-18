// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

pragma solidity ^0.8.1;

contract LotteryDapp {
    //global dynamic array for playerlist.
    uint public nowPlaying;
    uint public maxPlayer;
    uint public totalCashIn;
    uint public totalCashOut;
    uint public managementFee;
    uint public ticketPrice;
    uint public grandPrize;
    address payable public manager;
    address payable[] public playerList;
    address payable[] private winnerList; 
    uint []private payinList;
    uint []private payoutList;
    uint private seed;

    constructor() {
    //msg.sender is a global variable used to store contract address to manager.
    manager = payable(msg.sender); 
    managementFee = 10; //fixed. for project maintainance and promotions.
    ticketPrice = 0.0001 ether; // default amount per ticket.
    grandPrize = 1 ether; // default grandprize.
    totalCashIn = getCasinoVolume();
    totalCashOut = getTotalPayout();
    seed = (block.timestamp + block.difficulty) % 100;
    }

    // function that only manager can call.
    modifier onlyManager() {
    require(msg.sender == manager, "Only manager can call this");
        _;
    }

    //show total casinovolumes.
    function getCasinoVolume() internal view returns(uint) {
    return  msg.value;
    }

    //show total payouts.
    function getTotalPayout() internal view returns(uint){
    return payoutList.length;
    }
    //show player's currentTicketPrice.
    function getTickets() internal view returns(uint [] memory){
    return payinList;
    }

    //show to previous winner.
    function previousWinner() public view returns (address payable[] memory){
      return winnerList;
    }

    //function to set maxplayers.
    function setMaxPlayer(uint _maxPlayer) external onlyManager{ 
    require(nowPlaying == 0, "Game ongoing");
    maxPlayer = _maxPlayer;
    }

    //show total current casionbalance.
    function lotteryBalance() public view returns(uint){
    return address(this).balance;
    }

    //funtion to set ticketprice.
    function setTicketPrice(uint _ticketPrice) external onlyManager{
    require(nowPlaying == 0, "Game ongoing");
    ticketPrice = _ticketPrice;
    }

    //funtion to set rewardPrize.
    function setGrandPrize(uint _grandPrice) external onlyManager{
    require(nowPlaying == 0, "Game ongoing");
    grandPrize = _grandPrice;
    }

    //show to current payout.
    function previousGrandPrize() external view returns(uint [] memory){
    return payoutList;
    }
    //funtion during deposit.
    function callOnBuyTicket() internal {
    ticketPrice=(msg.value);
    totalCashIn+=((msg.value));
    payinList.push((msg.value));
    (bool sent,) = manager.call{value: ticketPrice/managementFee}("");
    require(sent, "Failed to send Ether");
    }

    //function to join game.
    function buyTicket() public payable {
    //require is used to assure gas is maximized by the users.
    require(msg.value == ticketPrice,"send exact ticketprice");
    if (lotteryBalance() < grandPrize  ){
    playerList.push(payable(msg.sender));
    nowPlaying++;
    callOnBuyTicket();
    }
    else if (lotteryBalance() > grandPrize){
    drawLottery();
    }
    }

    //sending/transfer is counted buyticket or join game. 
    receive() external payable{
    //require is used to assure gas is maximized by the users.
    require(msg.value == ticketPrice,"send exact ticketprice");
    if (lotteryBalance() < grandPrize  ){
    playerList.push(payable(msg.sender));
    nowPlaying++;
    callOnBuyTicket();
    }
    else if (lotteryBalance() > grandPrize){
    drawLottery();
    }
    }
    //call during reset and restart. 
    function clearLogs() internal {
    delete playerList;
    delete nowPlaying;
    delete payinList;
    }
    //call during reset and restart. 
    function clearAllLogs() internal {
    delete playerList;
    delete nowPlaying;
    delete payinList;
    delete winnerList;
    delete payoutList;
    ticketPrice = 0.0001 ether; // default amount per ticket.
    grandPrize = 1 ether; // default grandprize.
    }
    //call after pickwinner.
    function callAfterDrawLottery() internal {
    playerList.push(payable(msg.sender));
    payinList.push((msg.value));
    nowPlaying++;
    nowPlaying = 1;
    ticketPrice=(msg.value);
    totalCashIn+=((msg.value));
    }

    //this random function will generate random value and from player's array and then return to the pickWinner Function.
    function runRandom() public view returns(uint){
    return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,seed,playerList.length)));
    }

    // funtion to call automated choose winner randomly.
    function drawLottery() internal{
    require(address(this).balance > 0 ether, "Balance can not be less than zero"); 
    require(address(this).balance >= grandPrize,"reward insufficient");
    require(msg.value == ticketPrice,"send exact ticketprice");
    uint256 r = runRandom(); 
    uint256 index = r % playerList.length;
    address payable winner;
    winner = playerList[index];
    uint prizeAmount = grandPrize;
    winner.transfer(prizeAmount);
    winnerList.push(payable(winner));
    payoutList.push((prizeAmount));
    totalCashOut+=((prizeAmount));
    clearLogs();
    callAfterDrawLottery();
    }

    //funtion only manager can call the smart contract to restartgame.
    function restart() external onlyManager {
    clearAllLogs();
    }
    // Function to rescue any erc20 token accidentally sent to the contract.
    function rescueERC20(IERC20 token, address to, uint256 amount) external onlyManager{
    uint256 erc20balance = token.balanceOf(address(this));
    require(amount <= erc20balance, "balance is low");
    token.transfer(to, amount);
    }  
}
