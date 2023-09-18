pragma solidity ^0.4.9;

import "remix_tests.sol";
import "./lottery.sol";

contract LotteryTests 
{
    Lottery lottery;
    uint256 TICKET_COST = 50000;
    uint256 DRAW_DATE = 9999999999;
    
    constructor() public
    {
        lottery = new Lottery();
    }
    
    function setupGameTest() public
    {
       lottery.setupGame(TICKET_COST, DRAW_DATE);
       
       (uint256 ticketCost, uint256 drawDate, uint256 prizePool) = lottery.gameInfo();
       
       Assert.equal(ticketCost, TICKET_COST, "Ticket price is not correct");
       Assert.equal(drawDate, DRAW_DATE, "Draw date is not correct");
       Assert.equal(prizePool, 0, "Initial Prize Poll must be 0");
    }
}
