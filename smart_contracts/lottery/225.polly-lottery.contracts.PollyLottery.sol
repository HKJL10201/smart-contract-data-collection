// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "hardhat/console.sol";



/**
 * @title Lottery
 * @dev Simple lottery contract where users can enter and a random winner is chosen
 * after the deadline has passed.
 */

contract PollyLottery {
    // Player struct
    struct Player {
        address  addr;
        uint256 ticketNumber;
    }

    // Lottery info
    address  owner;
    uint256 public deadline;
    uint256 public ticketPrice;

    // Players
    mapping(uint256 => Player) public players;
    uint256 public playerCount;

    // Winning player
    address public winner;
    bool public winnerSet;

    // Events
    event NewPlayer(address player);
    event LotteryEnded();
    event LotteryWinner(address winner);

     constructor() {
        owner = msg.sender;
        ticketPrice = 0.05 ether;
        deadline = block.timestamp;
        
    }

    /**
     * @dev Allows a player to enter the lottery by sending the ticketPrice in wei
     * to the contract.
     */
    
     // Getter smart contract Balance
    function getBalance() external view returns(uint) {
        return address(this).balance;
    }
    function getPlayers() external view returns(uint) {
        return playerCount;
    }
    function enterDraw() public payable{
        require(
            msg.value == ticketPrice,
            "Incorrect ticket price. Please send the correct amount to enter the lottery."
        );
        require(
            ticketPrice > 0,
            "TicketPrice is low"
        );

        // Create a new player and assign them a ticket number
        Player memory newPlayer = Player(msg.sender, playerCount + 1);
        players[playerCount + 1] = newPlayer;

        playerCount++;
        emit NewPlayer(msg.sender);
    }
    function isOwner (address _addr) external view returns(bool) {
        bool yes = true;
        if(_addr != owner){
            return false;
        }
        return yes;

    }

    /**
     * @dev Picks a random winner from the players and ends the lottery. Can only
     * be called by the contract owner after the deadline has passed.
     */
     
    function pickWinner() public {
        require(
            msg.sender == owner,
            "Only the contract owner can pick the winner."
        );
        require(
            block.timestamp  > deadline,
            "The deadline has not passed yet. Cannot pick a winner."
        );

        // Generate a random number between 1 and the number of players
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, playerCount))) % playerCount;

        // Find the player with the random ticket number
        Player memory selectedPlayer = players[random];
        winner = selectedPlayer.addr;
        winnerSet = true;

        emit LotteryEnded();
        emit LotteryWinner(winner);
    }

    /**
     * @dev Allows the winner to withdraw their winnings from the contract.
     */
     function isWinner (address _addr) external view returns(bool) {
        bool yes = true;
        if(_addr != winner){
            return false;
        }
        return yes;

    }
    function withdrawWinnings() public payable{
        require(
            winnerSet == true,
            "A winner has not been picked yet. Cannot withdraw winnings."
        );
        require(
            msg.sender == winner,
            "Only the winner can withdraw their winnings."
        );

        payable(winner).transfer(address(this).balance);
    }

    /**
     * @dev Allows the contract owner to withdraw the contract balance.
     */
   

}

