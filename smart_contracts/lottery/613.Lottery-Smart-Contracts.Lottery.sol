// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Lottery {
    address public manager;
    
    address payable[] public players;

    constructor() {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value > .001 ether);
        // checking to see amount
        players.push(payable(msg.sender));
    }


// Do not use this as a hacker can instead read the code and find the secret number. Instead use oracles like chainlink VRF.
    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, players)
                )
            );
    }

    modifier restricter() {
        require(msg.sender == manager);
        _;
    }

    function pickWiner() public restricter {
        uint256 index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address payable[](0);
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
}
