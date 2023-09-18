// Simple contract for creating a lottery.
// Do NOT use for production (it has not been tested and uses pseudorandom numbers)

// update March 2019  to solidity 0.5.0
// https://solidity.readthedocs.io/en/latest/050-breaking-changes.html
pragma solidity ^0.5.1;

// select winner based on a large number divided thru modulo and players length
contract Lottery {
    // the owner of the contract to determine winner
    address public admin;

    address payable[] public players;

    // store the address of the person who created contract
    constructor(Lottery) public {

        // access to msg always within contract
        admin = msg.sender;
    }

    // payable used if money being sent along into the contract
    function enter() public payable {
        // the min amount of ehter which has to be invested into the lottery
        require(msg.value > .05 ether);
        players.push(msg.sender);

    }

    // view does not modify anything just returns pseudo random value bc values are known like currenttime
    function random() private view returns (uint) {
        // subclass of sha3 and casting hash to uint
        // uint returnValue = uint(keccak256(block.difficulty, now, players));
        uint returnValue;

        // todo: use oracle

        return returnValue;
    }

    // Pick the winner here using the pseudo random number and the modulo to get the index between 0 and lenght
    // key function of the contract which can only be executed by the admin
    function pickWinner() public restricted {

        // calculation of the winner
        uint indexWinner = random() % players.length;
        // this.balance = whole balance of contract: send this to player
        // players[indexWinner].transfer(this.balance);
        players[indexWinner].transfer(address(this).balance);

        // create new array of addresses to clean players
        // players = new address[](0);
        players = new address payable [](0);

    }

    // special modifier method to not repeat code aka inheritance like
    // Always use 1...n modifiers for repeated logic
    modifier restricted() {
        // ensure only the admin/contract creator can call here
        require(msg.sender == admin);
        _; // placeholder for the code of the other functions

    }

    // Return the complete array of player addresses
    // no data of contract changed --> view
    function getPlayers() public view returns(address payable[] memory) {
        return players;

    }

    // Return the balance paid into the lottery account
    // no data of contract changed --> view only
    function getTotalBalance() public view returns(uint) {
        return address(this).balance;
    }
}

// References:
// https://ethereum.stackexchange.com/questions/63121/version-compatibility-issues-in-solidity-0-5-0-and-0-4-0
// https://ethereum.stackexchange.com/questions/62906/typeerror-data-location-must-be-memory-for-parameter-in-function-but-none-wa
// https://blog.oraclize.it/the-random-datasource-chapter-2-779946e54f49
