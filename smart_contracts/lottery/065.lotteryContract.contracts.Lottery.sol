// SPDX-License-Identifier: MIT

pragma solidity ^0.4.17;

contract Lottery {

    address public manager;
    uint256 public prizePool;
    uint256 public contractFunds;

    /*
    struct Player {
        address playerAddress;
        uint256 wager;
    }
    */

    mapping(address => uint256) public addressToBet;
    address[] public players;
    //Player[] public playersAndWager; // Used if rewriting to # tickets by how much the player wager

    // Constructor function to make the deployer address into the owner/manager
    function Lottery() public {
        manager = msg.sender;
    }

    // Modifier for owner of contract
    modifier onlyManager{
        require(msg.sender == manager);
        _;
    }

    // Enter into the lottery
    function enter() public payable {
        require(msg.value > 0.002 ether);
        //playersAndWager.push(Player(msg.sender, msg.value - 0.01 ether));
        players.push(msg.sender);
        addressToBet[msg.sender] += msg.value;
        prizePool += (msg.value - 0.01 ether);
        contractFunds += 0.01 ether;
    }

    // Pseudo randomness for picking a winner
    function random() private view returns(uint256) {
        return uint256(keccak256(block.difficulty, now, players));
    }

    // Pick a winner, and send all money to the winner
    function pickWinner() public onlyManager {

        // Pick a winner "randomly"
        uint _winnerIndex = random() % players.length;

        // Transfer out the prizepool to the winner
        //players[_winnerIndex].transfer(this.balance); // Everything
        players[_winnerIndex].transfer(prizePool); // PrizePool only

        // Reset the mapping for next round
        for(uint i; i < players.length; i++){
            addressToBet[players[i]] = 0;
        }

        // Reset players and prizePool for next round
        players = new address[](0);
        //playersAndWager = new Player[](0);
        prizePool = 0;
    }

    // Withdraw the contract funds (profit) off running the Lottery to an address
    function withdrawFunds(address _withdrawAddress) public onlyManager {
        _withdrawAddress.transfer(contractFunds);
    }

    // Return all the players
    function getPlayers() public view returns(address[]) {
        return players;
    }
}
