/**
  * @Lottery.sol
  * @author  Sanchit Balchandani <balchandani.sanchit@gmail.com>
  *
  * The smart contract is about a Lottery Game on ethereum blockchain
  * which allows owner of the contract to instantiate the lottery and have
  * the first ticket on his name, as soon as all tickets are sold out, a
  * winner is declared via Event and the winningAmount is transferred to
  * the winner's address.
  * Incase, all tickets doesn't get sold, so owner has the functionality to
  * end the lottery, which would find the winner at that particular point and
  * send the winningAmount to winner's address.
 */
pragma solidity 0.4.18;

import "./helper_contracts/zeppelin/Ownable.sol";


/** Ethereum Lottery Smart Contract.*/
contract Lottery is Ownable {
    uint internal numTickets;
    uint internal availTickets;
    uint internal ticketPrice;
    uint internal winningAmount;
    bool internal gameStatus;
    uint internal counter;

    // mapping to have counter to address value.
    mapping (uint => address) internal players;
    // mapping to have address to bool value.
    mapping (address => bool) internal playerAddresses;

    // Event which would be emmitted once winner is found.
    event Winner(uint indexed counter, address winner, string mesg);

    /** getLotteryStatus function returns the Lotter status.
      * @return numTickets The total # of lottery tickets.
      * @return availTickets The # of available tickets.
      * @return ticketPrice The price for one lottery ticket.
      * @return gameStatus The Status of lottery game.
      * @return contractBalance The total available balance of the contract.
     */
    function getLotteryStatus() public view returns(uint, uint, uint, bool, uint) {
        return (numTickets, availTickets, ticketPrice, gameStatus, winningAmount);
    }

    /** startLottery function inititates the lottery game with #tickets and ticket price.
      * @param tickets - no of max tickets.
      * @param price - price of the ticket.
     */
    function startLottery(uint tickets, uint price) public payable onlyOwner {
        if ((tickets <= 1) || (price == 0) || (msg.value < price)) {
            revert();
        }
        numTickets = tickets;
        ticketPrice = price;
        availTickets = numTickets - 1;
        players[++counter] = owner;
        // increase the winningAmount
        winningAmount += msg.value;
        // set the gameStatus to True
        gameStatus = true;
        playerAddresses[owner] = true;
    }

    /** function playLotter allows user to buy tickets and finds the winnner,
      * when all tickets are sold out.
     */
    function playLottery() public payable {
        // revert in case user already has bought a ticket OR,
        // value sent is less than the ticket price OR,
        // gameStatus is false.
        if ((playerAddresses[msg.sender]) || (msg.value < ticketPrice) || (!gameStatus)) {
            revert();
        }
        availTickets = availTickets - 1;
        players[++counter] = msg.sender;
        winningAmount += msg.value;
        playerAddresses[msg.sender] = true;
        // reset the Lotter as soon as availTickets are zero.
        if (availTickets == 0) {
            resetLottery();
        }
    }

    /** getGameStatus function to get value of gameStatus.
      * @return gameStatus - current status of the lottery game.
     */
    function getGameStatus() public view returns(bool) {
        return gameStatus;
    }

    /** endLottery function which would be called only by Owner.
     */
    function endLottery() public onlyOwner {
        resetLottery();
    }

    /** getWinner getter function.
      * this calls getRandomNumber function and
      * finds the winner using players mapping
     */
    function getWinner() internal {
        uint winnerIndex = getRandomNumber();
        address winnerAddress = players[winnerIndex];
        Winner(winnerIndex, winnerAddress, "Winner Found!");
        winnerAddress.transfer(winningAmount);
    }

    /** getRandomNumber function, which finds the random number using counter.
     */
    function getRandomNumber() internal view returns(uint) {
        uint random = uint(block.blockhash(block.number-1))%counter + 1;
        return random;
    }

    /** resetLottery function resets lottery and find the Winner.
     */
    function resetLottery() internal {
        gameStatus = false;
        getWinner();
        winningAmount = 0;
        numTickets = 0;
        availTickets = 0;
        ticketPrice = 0;
        counter = 0;
    }
}