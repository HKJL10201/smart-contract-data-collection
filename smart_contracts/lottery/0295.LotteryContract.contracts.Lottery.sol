pragma solidity ^0.4.17;

contract Lottery {

    address public manager;
    address[] public players;

    mapping(address => uint) public wagerOf;

    // Assign the creator of the contract as the manager
    constructor() public {
        manager = msg.sender;
    }

    // Enter a player into the lottery
    function enter() public payable {

        // Require each player to send enough ether
        require(msg.value > 0.001 ether);

        // Add sender to the list of players
        players.push(msg.sender);

        // Keep track of the player's wager
        wagerOf[msg.sender] = msg.value;
    }

    // Send the contract's total balance to a random player
    function pickWinner() public onlyManager {

        // Can only pick the winner if the array has at least one player
        require(players.length > 0);

        // Pick a random player to be the winner
        uint index = random() % players.length;

        // Send the total balance to the winner
        players[index].transfer(address(this).balance);

        // Reset the array for the next game
        players = new address[](0);
    }

    // Generate a pseudo-random number
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, players)));
    }

    // Returns all wagers to each player without picking a winner
    function cancelLottery() public onlyManager {

      for (uint i = 0; i < players.length; i++) {
        players[i].transfer(wagerOf[players[i]]);
        wagerOf[players[i]] = 0;
      }

      // Reset the array for the next game
      players = new address[](0);
    }

    // Get the entire list of players in the lottery
    function getPlayers() public view returns (address[]) {
        return players;
    }

    // Only the manager can do the function
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }


}
