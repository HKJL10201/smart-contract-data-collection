// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./newNFT.sol";
//import "./Ticket.sol";
import "hardhat/console.sol";

/** 
 * @title Try
 * @dev Implements lottery
 */

contract Try {

    /*struct Ticket {
        address owner;
        uint[6] numbers;
        uint round;
    }*/

    struct Ticket {
        address owner;
        uint number1;
        uint number2;
        uint number3;
        uint number4;
        uint number5;
        uint jolly;
        uint round;
    }

    uint public K = 8;
    uint public m;
    uint public price = 30000000 gwei;  //approximately 50€
    
    uint256 public startingBlock;
    uint256[8] public prizes;

    uint public roundNumber = 0;
    uint[6] public drawnNumbers;
    uint[] public class;
    uint public winnersLen;
    uint public ticketsLen;

    bool public activeRound = false;
    bool public prizesDistributed;
    bool public isActive = true;

    address public lotteryManager;
    address[] public winners;

    newNFT public minter;

    Ticket[] public tickets; 

    event RoundStarted(uint roundNumber);
    event RoundClosed(uint[6] drawnNumbers, address[] winners, uint[] class, uint len);
    event TicketBought(address owner, uint[6] ticket);  
    event LotteryClosed();

    constructor () //when a new instance is created, activate a new round and initialize a lottery manager
        payable 
    { 
        lotteryManager = msg.sender;
        minter = new newNFT();
        for (uint i = 0; i <= 7; i++){
            prizes[i] = minter.awardItem(i);
        }
        //startNewRound();
    }

    modifier checkActive() //check if the contract is still active
    {
        require (isActive);
        _;
    }

    function startNewRound (uint blocks) //start a new round
        checkActive
        public 
        returns (bool)
    { 
        require(!activeRound, "Lottery already open!");
        require(lotteryManager == msg.sender, "Only the lottery manager can start a new round.");
        delete tickets;
        ticketsLen = 0;
        //delete drawnNumbers;
        //delete winners;
        m = blocks;
        roundNumber += 1;
        startingBlock = block.number;
        prizesDistributed = false;
        activeRound = true;
        emit RoundStarted(roundNumber);
        return true;
    }

    function buy (uint[6] memory numbers) //buy a ticket
        checkActive
        public 
        payable
    { 
        uint gasNow = gasleft();

        require(activeRound, "Lottery closed");
        require(msg.sender != lotteryManager, "Lottery manager cannot play, sigh...");
        require(msg.value == price, "Not enough money!");
        //require(block.number < startingBlock + m, "Wait, some other blocks have to be mined.");

        console.log(gasNow-gasleft());

        bool validTicket = true;
        bool exit = false;

        gasNow = gasleft();

        for (uint i = 0; i < numbers.length - 1; i++){ // check if the choosen numbers are unique
            if (numbers[i] < 1 || numbers[i] > 69){
                validTicket = false;
                break;
            }
            for (uint j = i + 1; j < numbers.length - 1; j++){
                if (numbers[i] == numbers[j]){
                    validTicket = false;
                    exit = true;
                    break;
                }
            }
            if (exit == true) { 
                break;
            }
            console.log(uint(numbers[i]));
        }
        if (numbers[5] < 1 || numbers[5] > 26){
            validTicket = false;
        }

        console.log(gasNow-gasleft());

        gasNow = gasleft();

        require(validTicket, "Each number must be unique!");
        Ticket memory newTicket = Ticket(msg.sender, numbers[0], numbers[1], numbers[2], numbers[3], numbers[4], numbers[5], roundNumber);
        tickets.push(newTicket);
        ticketsLen = tickets.length;
        emit TicketBought(msg.sender, numbers);
    }

    function drawNumbers () //extract numbers
        checkActive
        internal
        returns (bool)
    {   
        require(!activeRound, "A new lottery round will start soon...");
        bool debug = true;
        if (debug){
            drawnNumbers[0] = 1; drawnNumbers[1] = 2; drawnNumbers[2] = 3; drawnNumbers[3] = 4; drawnNumbers[4] = 5; drawnNumbers[5] = 6;
        } else {
            uint lastExtraction = uint((uint256(keccak256(abi.encode(/*blockhash(*/block.number+ K, block.difficulty, block.timestamp)))));
            for (uint j = 0; j < 5; j++){
                lastExtraction = uint((uint256(keccak256(abi.encode(/*abi.encode(blockhash(*/block.number + K, block.difficulty/*)*/, block.timestamp, lastExtraction))) % 69) + 1);
                drawnNumbers[j] = lastExtraction;
                console.log(uint(drawnNumbers[j]));
            }
            drawnNumbers[5] = uint((uint256(keccak256(abi.encode(/*abi.encode(blockhash(*/block.number + K, block.difficulty/*)*/, block.timestamp, lastExtraction))) % 29) + 1);  
            console.log(drawnNumbers[5]);
        }
        return true;
    } 
    
    function givePrizes () 
        checkActive
        internal 
        returns (bool)
    {
        require(!activeRound, "A new round will start soon");
        require(!prizesDistributed, "Prizes already distributed.");
        for (uint i = 0; i < tickets.length; i++){ //loop over each ticket bought
            uint count = 0;
            bool jolly = false;
            
            for (uint x = 0; x < 5; x++){
                if (drawnNumbers[x] == tickets[i].number1 || drawnNumbers[x] == tickets[i].number2 || drawnNumbers[x] == tickets[i].number3 || drawnNumbers[x] == tickets[i].number4 || drawnNumbers[x] == tickets[i].number5){
                    count++;
                }
            }
            if (tickets[i].jolly == drawnNumbers[5]){ //checking the jolly
                jolly = true;
            }
            address currentOwner = tickets[i].owner;
            if (count == 5 && jolly){
                minter.rewardWinner(currentOwner, prizes[0]);
                console.log("The following address won the 1st prize: ");
                console.log(currentOwner);
                winners.push(currentOwner);
                class.push(1);
                prizes[0] = mint(0);
            } else if (count == 5 && !jolly){
                minter.rewardWinner(currentOwner, prizes[1]);
                winners.push(currentOwner);
                class.push(2);
                console.log("The following address won the 2nd prize: ");
                console.log(currentOwner);
                prizes[1] = mint(1);
            } else if (count == 4 && jolly){
                minter.rewardWinner(currentOwner, prizes[2]);
                winners.push(currentOwner);
                class.push(3);
                console.log("The following address won the 3rd prize: ");
                console.log(currentOwner);
                prizes[2] = mint(2);
            } else if ((count == 4 && !jolly) || (count == 3 && jolly)){
                minter.rewardWinner(currentOwner, prizes[3]);
                winners.push(currentOwner);
                class.push(4);
                console.log("The following address won the 3rd prize: ");
                console.log(currentOwner);
                prizes[3] = mint(3);
            } else if ((count == 3 && !jolly) || (count == 2 && jolly)){
                minter.rewardWinner(currentOwner, prizes[4]);
                winners.push(currentOwner);
                class.push(5);
                console.log("The following address won the 4th prize: ");
                console.log(currentOwner);
                prizes[4] = mint(4);
            } else if ((count == 2 && !jolly) || (count == 1 && jolly)){
                minter.rewardWinner(currentOwner, prizes[5]);
                winners.push(currentOwner);
                class.push(6);
                console.log("The following address won the 4th prize: ");
                console.log(currentOwner);
                prizes[5] = mint(5);
            } else if (count == 1 && !jolly){
                minter.rewardWinner(currentOwner, prizes[6]);
                winners.push(currentOwner);
                class.push(7);
                console.log("The following address won the 5th prize: ");
                console.log(currentOwner);
                prizes[6] = mint(6);
            } else if (count == 0 && jolly){
                minter.rewardWinner(currentOwner, prizes[7]);
                winners.push(currentOwner);
                class.push(8);
                console.log("The following address won the 5th prize: ");
                console.log(currentOwner);
                prizes[7] = mint(7);
            } else {
                console.log("The following address didn't win: ");
                console.log(currentOwner);
            } 
            console.log("one iteration completed");
        }
        winnersLen = winners.length;
        prizesDistributed = true;
        return true;
    } 

    function mint (uint index)  // used to mint new collectibles
        checkActive
        internal 
        returns (uint256 tokenId)
    {
        require(0 <= index && index <= 7, "Index out of bounds.");
        return minter.awardItem(index);
    }

    function refund () //refund all the players if the round is closed before m blocks
        checkActive
        public
        payable
        returns (bool)
    {
        for (uint i = 0; i < tickets.length; i++){
            address currentOwner = tickets[i].owner;
            payable(currentOwner).transfer(price);
        }
        return true;
    } 

    function closeRound () //stops a round
        checkActive
        public 
        payable
        returns(bool)
    {
        require(activeRound, "Lottery already close!");
        require(lotteryManager == msg.sender, "Only the lottery manager can close a round.");
        delete drawnNumbers;
        delete winners;
        delete class;

        activeRound = false;
        if (block.number < startingBlock + m){
            refund();
        } else {
            payable(lotteryManager).transfer(address(this).balance); //send the contract balance to the lottery manager
            drawNumbers(); //extract numbers
            givePrizes(); //give prizes
        }

        emit RoundClosed(drawnNumbers, winners, class, winnersLen);
        return true;
    }

    function closeLottery ()
        public
    {
        require(msg.sender == lotteryManager, "Only the lottery manager can close the contract.");
        isActive = false;
        emit LotteryClosed();
    }

}