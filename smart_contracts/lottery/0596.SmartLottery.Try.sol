// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./newNFT.sol";
import "./Ticket.sol";
import "hardhat/console.sol";

/** 
 * @title Try
 * @dev Implements lottery
 */

contract Try {
   
    uint public K = 8;
    uint public m;
    uint public price = 30000000 gwei;  //approximately 50€
    
    uint256 public startingBlock;
    uint256[8] public prizes;

    int public roundNumber = 0;
    int[6] public drawnNumbers;

    bool public activeRound = false;
    bool public prizesDistributed;
    bool public isActive = true;

    address public lotteryManager;

    newNFT public minter;

    Ticket[] public tickets; 

    event RoundStarted(int roundNumber);
    event RoundClosed(int[6] drawnNumbers, Ticket[] tickets);
    event TicketBought(Ticket newTicket);

    constructor (uint blocks) //when a new instance is created, activate a new round and initialize a lottery manager
        payable 
    { 
        lotteryManager = msg.sender;
        minter = new newNFT();
        m = blocks;
        for (uint i = 0; i <= 7; i++){
            prizes[i] = minter.awardItem(i);
        }
        startNewRound();
    }

    modifier checkActive() //check if the contract is still active
    {
        require (isActive);
        _;
    }

    function random6() //this function generate 6 random numbers 
        checkActive
        internal  
        returns (bool)
    {   //bytes32 bhash = blockhash(block.number + K);
        bool debug = false;
        if (debug){
            drawnNumbers[0] = 1; drawnNumbers[1] = 2; drawnNumbers[2] = 3; drawnNumbers[3] = 4; drawnNumbers[4] = 5; drawnNumbers[5] = 6;
        } else {
            int lastExtraction = int((uint256(keccak256(abi.encode(/*blockhash(*/block.number+ K, block.difficulty)))));
            for (uint j = 0; j < 5; j++){
                lastExtraction = int((uint256(keccak256(abi.encode(/*abi.encode(blockhash(*/block.number + K, block.difficulty/*)*/, lastExtraction))) % 69) + 1);
                drawnNumbers[j] = lastExtraction;
                console.log(uint(drawnNumbers[j]));
            }
            drawnNumbers[5] = int((uint256(keccak256(abi.encode(/*abi.encode(blockhash(*/block.number + K, block.difficulty/*)*/, lastExtraction))) % 29) + 1);  
            console.log(uint(drawnNumbers[5]));
        }
        return true;
    } 

    function startNewRound () //start a new round
        checkActive
        public 
        returns (bool)
    { 
        require(!activeRound, "Lottery already open!");
        require(lotteryManager == msg.sender, "Only the lottery manager can start a new round.");
        roundNumber += 1;
        startingBlock = block.number;
        delete drawnNumbers;
        delete tickets;
        prizesDistributed = false;
        activeRound = true;
        emit RoundStarted(roundNumber);
        return true;
    }

    function buy (int[6] memory numbers) //buy a ticket
        checkActive
        public 
        payable
    { 
        uint gasNow = gasleft();

        require(activeRound, "Lottery closed");
        require(msg.sender != lotteryManager, "Lottery manager cannot play, sigh...");
        require(msg.value == price, "Not enough money!");
        require(block.number < startingBlock + m, "Wait, some other blocks have to be mined.");

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
        Ticket newTicket = new Ticket(msg.sender, numbers, roundNumber);
        tickets.push(newTicket);
        emit TicketBought(newTicket);
    }

    function drawNumbers () //ectract numbers
        checkActive
        internal
        returns (bool)
    { 
        require(!activeRound, "A new lottery round will start soon...");
        random6();
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
            int count = 0;
            bool jolly = false;
            int[6] memory numbersPlayed = tickets[i].getNumbers();
            for (uint j = 0; j < 6; j++){ //loop over the numbers of the tickets
                console.log(uint(numbersPlayed[j]));
                for (uint x = 0; x < 6; x++){
                    if (numbersPlayed[j] == drawnNumbers[x]){
                        count++;
                        break;
                    }
                }
            }
            console.log(uint(numbersPlayed[5]));
            if (numbersPlayed[5] == drawnNumbers[5]){ //checking the jolly
                jolly = true;

            }

            address currentOwner = tickets[i].getOwner();
            if (count == 5 && jolly){
                minter.rewardWinner(currentOwner, prizes[0]);
                //winners.push(currentOwner);
                console.log("The following address won the 1st prize: ");
                console.log(currentOwner);
                prizes[0] = mint(0);
            } else if (count == 5 && !jolly){
                minter.rewardWinner(currentOwner, prizes[1]);
                //winners.push(currentOwner);
                console.log("The following address won the 2nd prize: ");
                console.log(currentOwner);
                prizes[1] = mint(1);
            } else if (count == 4 && jolly){
                minter.rewardWinner(currentOwner, prizes[2]);
                //winners.push(currentOwner);
                console.log("The following address won the 3rd prize: ");
                console.log(currentOwner);
                prizes[2] = mint(2);
            } else if ((count == 4 && !jolly) || (count == 3 && jolly)){
                minter.rewardWinner(currentOwner, prizes[3]);
                //winners.push(currentOwner);
                console.log("The following address won the 3rd prize: ");
                console.log(currentOwner);
                prizes[3] = mint(3);
            } else if ((count == 3 && !jolly) || (count == 2 && jolly)){
                minter.rewardWinner(currentOwner, prizes[4]);
                //winners.push(currentOwner);
                console.log("The following address won the 4th prize: ");
                console.log(currentOwner);
                prizes[4] = mint(4);
            } else if ((count == 2 && !jolly) || (count == 1 && jolly)){
                minter.rewardWinner(currentOwner, prizes[5]);
                //winners.push(currentOwner);
                console.log("The following address won the 4th prize: ");
                console.log(currentOwner);
                prizes[5] = mint(5);
            } else if (count == 1 && !jolly){
                minter.rewardWinner(currentOwner, prizes[6]);
                //winners.push(currentOwner);
                console.log("The following address won the 5th prize: ");
                console.log(currentOwner);
                prizes[6] = mint(6);
            } else if (count == 0 && jolly){
                minter.rewardWinner(currentOwner, prizes[7]);
                //winners.push(currentOwner);
                console.log("The following address won the 5th prize: ");
                console.log(currentOwner);
                prizes[7] = mint(7);
            } else {

                console.log("The following address didn't win: ");
                console.log(currentOwner);
            }
            
        }
        prizesDistributed = true;
        return true;
    } 

    function mint (uint index)  // used to mint new collectibles
        checkActive
        internal 
        returns (uint256 tokenId)
    {
        require(0 < index && index <= 7, "Index out of bounds.");
        return minter.awardItem(index);
    }

    function refund () //refund all the players if the round is closed before m blocks
        checkActive
        public
        payable
        returns (bool)
    {
        for (uint i = 0; i < tickets.length; i++){
            address currentOwner = tickets[i].getOwner();
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
        activeRound = false;
        if (block.number < startingBlock + m){
            refund();
        } else {
            payable(lotteryManager).transfer(address(this).balance); //send the contract balance to the lottery manager
            drawNumbers(); //extract numbers
            givePrizes(); //give prizes
        }
        emit RoundClosed(drawnNumbers, tickets);
        return true;
    }

    function closeLottery ()
        public
    {
        require(msg.sender == lotteryManager, "Only the lottery manager can close the contract.");
        isActive = false;
    }

}
