pragma solidity ^0.4.11;
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract SmartDice is usingOraclize {

    string public lastRoll;
    string public lastPrice;
    address owner;
    event diceRolled(uint value);

    function SmartDice() payable {
        rollDice();
        owner = msg.sender;
    }

    function __callback(bytes32 myid, string result) {
        if (msg.sender != oraclize_cbAddress()) throw;
        lastRoll = result;
        diceRolled(parseInt(lastRoll));
    }

    function rollDice() payable returns (bool) {
        // Retrieve price for oraclize query
        uint oraclizePrice = oraclize_getPrice("WolframAlpha");

        // Check the price is covered by the transaction
        if (msg.value < oraclizePrice) {
          return false;
        }

        // Update last lastPrice
        lastPrice = uint2str(oraclizePrice);

        // Call WolframAlpha via Oraclize to roll the dice
        oraclize_query("WolframAlpha", "random number between 1 and 6");

        return true;
    }

    function withdraw(uint amount) returns (bool) {
        // Only the owner may withdraw
        if (msg.sender != owner) {
            return false;
        }

        // Sanity check balance
        if (amount > this.balance) {
            return false;
        }

        // Try to send, throw if
        if (!msg.sender.send(amount)) {
            return false;
        }

        return true;
    }
}
