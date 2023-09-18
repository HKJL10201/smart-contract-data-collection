// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    address public manager;
    address[] public players;

    constructor() {
        manager = msg.sender;
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function enter() public payable {
        assert(msg.value > 0.1 ether);
        players.push(msg.sender);
    }

    function random() private view returns (uint256) {
                return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, players)
                )
            );
    }

    function pickWinner() public restricted {
        uint256 _index = random() % players.length;
        address _winner = payable(players[_index]);
        players = new address[](0);
        (bool sent,) = _winner.call{value: address(this).balance} ("");
        require(sent, "Ether not sent");
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }
}