// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    address payable public manager;
    address payable[] public players;

    constructor() {
        manager = payable(msg.sender);
    }

    modifier restricted() {
        require(payable(msg.sender) == manager);
        _;
    }

    function enter() public payable {
        require(msg.value > 0.01 ether);

        players.push(payable(msg.sender));
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(block.difficulty, block.timestamp, players)
                )
            );
    }

    function pickWinner() public payable restricted {
        require(players.length > 0, "Need at least one player.");

        uint256 index = random() % players.length;

        players[index].transfer(address(this).balance);

        players = new address payable[](0);
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
}
