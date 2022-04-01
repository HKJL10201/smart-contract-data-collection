//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract Lottery {
    //manager is in charge of the contract
    address public manager;
    //new player in the contract using array[] to unlimit number
    address[] public players;

    constructor() {
        manager = msg.sender;
        console.log("Manager", manager);
    }

    //to call the enter function we add them to players
    function enter() public payable {
        //each player is compelled to add a certain ETH to join
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }

    //creates a random hash that will become our winner
    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encode(block.timestamp, players)));
    }

    function pickWinner() public payable restricted returns (uint256) {
        // only the manager can pickWinner
        require(msg.sender == manager);
        // creates index that is gotten from func random % play.length
        uint256 index = random() % players.length;

        console.log("The winner is", players[index]);
        // pays the winner picked randomely(not fully random)
        require(payable(players[index]).send(address(this).balance));
        // empies the old lottery and starts new one
        players = new address[](0);

        return index;
    }

    // get all the players
    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    // get the manager
    function getManager() public view returns (address) {
        return manager;
    }

    // get balance of the contract
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // get the number of players
    function getPlayersLength() public view returns (uint256) {
        return players.length;
    }

    // get the number of players
    function getPlayersIndex(uint256 index) public view returns (address) {
        return players[index];
    }

    // get balance player
    function getBalancePlayer(address _account) public view returns (uint256) {
        return address(_account).balance;
    }

    // modify the manager
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    // modify the manager
    function setManager(address _manager) public restricted {
        manager = _manager;
    }
}
