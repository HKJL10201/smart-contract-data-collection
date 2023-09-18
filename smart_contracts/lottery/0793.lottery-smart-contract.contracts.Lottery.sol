// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract Lottery {
    // global variable to store manager address
    address public manager;
    // global variable to store players addresses which are payable
    address payable[]  public players;

    constructor() {
        // manager is the person who deployed the contract
        manager = msg.sender;
    }

    /** Function to return the amount of eth in the lottery contract **/
    function getPriceMoneyBalance() public view returns (uint) {
        // .balance is the total eth sent to this contract.
        return address(this).balance;
    }

    /** Function to return all players separated by a comma **/
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    /** Function to enter in the lottery **/
    function enter() public payable {
        // check if the player hasn't already registered to the lottery
        for (uint i = 0; i < players.length; i++) require(msg.sender != players[i], '409: the player has already registered to the lottery.');

        // check if we send the good amount of ether to enter in the lottery
        require(msg.value > .01 ether, '402: below minimum wager.');

        // add the address of the player in the array
        players.push(payable(msg.sender));
    }

    function random() private view returns (uint) {
        //sha3
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
        // E.g. 60817645909108788401582706622900687126716325208998821960496561789277950725174
    }

    /** Function to enter in the lottery **/
    function pickWinner() public onlyManager {
        // get randomly a player then send to him the money
        // doesn't call a function to generate random number but put code directly here to have less gas fees
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        // Empty players array. old below use delete for new way
        // players = new address payable[](0);
        delete players;
    }

    modifier onlyManager() {
        // check if the person calling the function is the manager
        require(msg.sender == manager, '403: call restricted to manager.');

        // place holder to inject code inside when the modifier is used in a function
        _;
    }
}