// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <=0.9.0;

contract Lottery {
    address public admin;
    address payable[] private players;

    constructor() {
        admin = msg.sender;
    }

    function enter() external payable {
        require(
            msg.value > .01 ether,
            "Please make a deposit of at least .01 ether to enter"
        );
        players.push(payable(msg.sender));
    }

    function draw() external restricted {
        uint256 index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address payable[](0);
    }

    function getPlayers() external view returns (address payable[] memory) {
        return players;
    }

    modifier restricted() {
        require(msg.sender == admin, "Permission denied");
        _;
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, players)
                )
            );
    }
}
