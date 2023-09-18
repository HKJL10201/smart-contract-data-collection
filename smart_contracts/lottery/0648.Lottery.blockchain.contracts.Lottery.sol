pragma solidity ^0.8.11;

// External library used to manage random numbers
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

// Contract inheriting external library
contract Lottery is VRFConsumerBase {

    // Variables
    // Stores owner's address
    address public owner;

    // Stores players address
    address payable[] public players;

    // Stores current lottery id
    uint public lotteryId;

    // Stores all the lotteries winners address
    mapping (uint => address payable) public lotteryHistory;

    // Identifies which Chainlink oracle to use (LINKS)
    bytes32 internal keyHash;

    // Fee to get random number
    uint internal fee;

    // Stores a random number (Winner)
    uint public randomResult;

    // Constructor
    constructor()
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK token address
        ) {
            keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
            fee = 0.1 * 10 ** 18;    // 0.1 LINK

            // Assign owner's address to global variable
            owner = msg.sender;

            // Assign current lottery id to global variable
            lotteryId = 1;
        }

    // Request random number from external library using LINKS
    function getRandomNumber() public returns (bytes32 requestId) {
        // Validation of having enough LINKs in contract to request the random number
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK in contract");

        // Request random number
        return requestRandomness(keyHash, fee);
    }

    // Function to store the random number in randomResult
    function fulfillRandomness(bytes32 requestId, uint randomness) internal override {
        randomResult = randomness;
    }

    // Get winner of specific lottery
    function getWinnerByLottery(uint lottery) public view returns (address payable) {
        return lotteryHistory[lottery];
    }

    // Get balance of the total betting from the players
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    // Get all the current players playing
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    // Function which allows a player to enter the betting
    function enter() public payable {
        // Validation of having 0.1 ethereum minimum to enter the game
        require(msg.value > .01 ether);

        // Address of player entering the lottery
        players.push(payable(msg.sender));
    }

    // Function which picks a Winner, in this case a random number
    // NOTE: this function is linked to getRandomNumber function to make things
    // modularized and simpler to understand
    function pickWinner() public onlyOwner {
        getRandomNumber();
    }

    // Function which pays to the winner the total balance
    function payWinner() public onlyOwner {
        // Validation that checks if the random number was picked correctly
        require(randomResult > 0, "Must have a source of randomness before choosing winner");

        // Select winner's index using the randomResult
        uint index = randomResult % players.length;

        // Transfer the total balance to the winner
        players[index].transfer(address(this).balance);

        // Add lottery's winner address to lotteryHistory
        lotteryHistory[lotteryId] = players[index];

        // Increase lotteryId to store a new lottery game in lotteryHistory
        lotteryId++;

        // Reset the state of the contract
        players = new address payable[](0);
    }

    // Modifier which allows only the owner to access certain funcitons
    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
}
