pragma solidity ^0.4.22;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Lottery.sol";

contract TestLottery {
    Lottery lottery = Lottery(DeployedAddresses.Lottery());

    // Testing the adopt() function
    function testContractConstructor() public {
        uint ticketsIssued = 0;
        uint poolPrize = 0;
        uint ownerFee = 15;
        uint ticketPrice = 100 finney;
        uint nameChangePrice = 1000 finney;
        uint lotteryDuration = 24 hours;
        uint lotteryStart = now;

        Assert.equal(lottery.ticketsIssued, ticketsIssued, "0 tickets issued.");
        Assert.equal(lottery.poolPrize, poolPrize, "Pool prize is 0.");
        Assert.equal(lottery.ownerFee, ownerFee, "The owner fee is 15.");
        Assert.equal(lottery.ticketPrice, ticketPrice, "The ticket price is 100 finney.");
        Assert.equal(lottery.nameChangePrice, nameChangePrice, "The name change price is 1000 finney.");
        Assert.equal(lottery.lotteryDuration, lotteryDuration, "The lottery duration is 24 hours.");
        Assert.equal(lottery.lotteryStart, lotteryStart, "The lottery started this block.");
    }

}