// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    address public manager;
    address payable[] public players;

    constructor() {
        manager = msg.sender;
    }

    function enterLottery() public payable {
        require(msg.value > .01 ether);
        players.push(payable(msg.sender));
    }

    function randomNum() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, players)
                )
            );
    }

    function pickWinner() public restricted {
        uint256 index = randomNum() % players.length;
        players[index].transfer(address(this).balance);

        //emptying players array
        players = new address payable[](0);
    }

    function allPlayers() public view returns (address payable[] memory) {
        return players;
    }

    modifier restricted {
        require(msg.sender == manager);
        _;
    }
}
