// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.26;

contract Lottery {
    address public manager;
    address[] public players;

    constructor() public {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value > 0.001 ether);
        players.push(msg.sender);
    }

    function pickWinner() public restricted {
        uint256 index = random() % players.length;
        players[index].transfer(address(this).balance);
        // mark the player payable and convert contract to address
        // only for higher solidity versions
        players = new address[](0); // reset the contract
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, players)
                )
            );
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
        // underscore is replaced by the function marked as restricted
        // modifier name can be anything
        // just mention in the desired function
    }
}
