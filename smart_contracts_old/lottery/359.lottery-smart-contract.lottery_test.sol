pragma solidity ^0.4.24;
import "./remix_tests.sol"; // this import is automatically injected by Remix.
import "./lottery.sol";
import "./lottery_modifierless.sol";

// file name has to end with '_test.sol'
contract LotteryTest {
  Lottery lottery;
  Lottery_Modifierless lottery_modifierless;
  function beforeAll() {
    lottery = new Lottery(0xca35b7d915458ef540ade6068dfe2f44e8fa733c);
    lottery_modifierless = new Lottery_Modifierless(0xca35b7d915458ef540ade6068dfe2f44e8fa733c);
  }


  function TicketNumberRangeShouldNotExceed() public view returns (bool) {
    uint256 ticketNumber = 10000;
    bytes32 playerHash = keccak256("abc");


    return Assert.equal(
      address(lottery).call.gas(4000000).value(2 ether)("buyTickets",playerHash, ticketNumber),
      false,
      "ticket number range is not exceeded"
    );
  }


  function WrongAmoundOfPayementShouldRevert() public view returns (bool) {
    uint256 ticketNumber = 100;
    bytes32 playerHash = keccak256("abc");


    return Assert.equal(
      address(lottery).call.gas(4000000).value(1 ether)("buyTickets",playerHash, ticketNumber),
      false,
      "Less payement reverts"
    );
  }
  function TicketWrongPayementShouldRevert() public view returns (bool) {
    uint256 ticketNumber = 1000;
    bytes32 playerHash =keccak256("abc");


    return Assert.equal(
      address(lottery).call.gas(4000000).value(3 ether)("buyTickets",playerHash, ticketNumber),
      false,
      "More payement reverts"
    );
  }

  function TicketCantBeBoughtByTwoPerson() public view returns (bool) {
    uint256 ticketNumber = 1000;
    bytes32 playerHash = keccak256("abc");
    address(lottery).call.gas(4000000).value(2 ether)("buyTickets",playerHash, ticketNumber);


    return Assert.equal(
      address(lottery).call.gas(4000000).value(2 ether)("buyTickets",playerHash, ticketNumber),
      false,
      "tickets cannot be bought by two person"
    );
  }

  function RandomNumberIsCorrect()public view returns (bool){
    uint256 ticketNumber = 2032;
    uint256 randomNumber = 10;
    bytes32 playerHash = keccak256(randomNumber, ticketNumber, this);
    address(lottery).call.gas(4000000).value(2 ether)("buyTickets",playerHash, ticketNumber);

    return Assert.equal(
      address(lottery).call.gas(4000000000).value(0)("enterLottery",randomNumber, ticketNumber),
      true,
      "Random number correctly verified"
    );
  }
  function checkEnoughMoneyIsCollectedIsValid()public view returns (bool){
    uint256 randomNumber = 10;
    for(uint256 ticketNumber=0; ticketNumber<100000;ticketNumber++){
        bytes32 playerHash = keccak256(randomNumber, ticketNumber, this);
        address(lottery_modifierless).call.gas(4000000).value(2 ether)("buyTickets",playerHash, ticketNumber);
        address(lottery_modifierless).call.gas(4000000000).value(0)("enterLottery",randomNumber, ticketNumber);
    }

    return Assert.equal(
      address(lottery_modifierless).call.gas(4000000000).value(0)("generateWinners",randomNumber, ticketNumber),
      68400,
      "Enough Money is Collected"
    );
  }
}
