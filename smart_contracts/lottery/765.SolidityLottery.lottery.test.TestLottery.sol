pragma solidity ^0.4.23;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Lottery.sol";

contract TestLottery {

    uint public initialBalance = 10 ether;
    Lottery lottery;

    function beforeAll() public {
        lottery = Lottery(DeployedAddresses.Lottery());
    }

    function testZeroPlayersWhenZeroTicketsBought() public {
       address[] memory players = lottery.getPlayers();
        uint i = players.length;
        Assert.equal(uint(0), uint(i), "Expected zero players before any tickets bought");
    }

    function testPricePerTicketWhenContractDeployed() public {
        uint256 ticketPriceWei = lottery.getTicketPriceWei();

        Assert.equal(ticketPriceWei, 1000000, "Expected correct ticket price");
    }

    function testPayoutPerTicketWhenContractDeployed() public {
        uint256 payoutPerTicketWei = lottery.getPayoutPerTicketWei();

        Assert.equal(500000, payoutPerTicketWei, "Expected correct ticket payout");
    }

}