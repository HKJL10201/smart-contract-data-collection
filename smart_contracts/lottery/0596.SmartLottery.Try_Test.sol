// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "hardhat/console.sol";
import "contracts/Try.sol";
import "contracts/Ticket.sol";

contract TryTest {
   
    Try LotteryToTest = new Try(2);
    uint valueToSend = 1 gwei;

    function extractNumbers () 
        public 
        returns(int[6] memory, Ticket[] memory, Ticket[] memory) 
    {
        console.log("Stopping round and extracting numbers");
        int[6] memory numbers;
        Ticket[] memory tickets; 
        Ticket[] memory winners;
        (numbers, tickets, winners) = LotteryToTest.closeLottery();
        return (numbers, tickets, winners);
    }
    
    function buyNoMoneyTicket () public payable {
        console.log("Buying a ticket with not enough money");
        int[6] memory numbers;
        numbers[0] = 32; numbers[1] = 12; numbers[2] = 4; numbers[3] = 67; numbers[4] = 13; numbers[5] = 1;   
        Assert.equal(LotteryToTest.buy{value:1 wei}(numbers), false, "You can't play these numbers");
    }
        
    function buyDuplicatedTickets () public payable { 
        console.log("Buying a ticket with duplicated values");
        int[6] memory numbers;
        numbers[0] = 1; numbers[1] = 1; numbers[2] = 1; numbers[3] = 1; numbers[4] = 1; numbers[5] = 1;   
        Assert.equal(LotteryToTest.buy{value:valueToSend}(numbers), false, "You can't play these numbers");
    }

    function buySomeTickets () public payable { 
        console.log("Buying some valid tickets");
        int[6] memory numbers;
        numbers[0] = 1; numbers[1] = 2; numbers[2] = 3; numbers[3] = 4; numbers[4] = 5; numbers[5] = 6;   
        Assert.equal(LotteryToTest.buy{value:valueToSend}(numbers), true, "You can play these numbers");
        delete numbers;
        numbers[0] = 12; numbers[1] = 22; numbers[2] = 33; numbers[3] = 42; numbers[4] = 52; numbers[5] = 12;   
        Assert.equal(LotteryToTest.buy{value:valueToSend}(numbers), true, "You can play these numbers");
        delete numbers;
        numbers[0] = 65; numbers[1] = 25; numbers[2] = 32; numbers[3] = 49; numbers[4] = 55; numbers[5] = 6;   
        Assert.equal(LotteryToTest.buy{value:valueToSend}(numbers), true, "You can play these numbers");
        delete numbers;
        
    }
}
