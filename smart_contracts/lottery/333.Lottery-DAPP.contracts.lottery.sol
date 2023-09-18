// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract lottery {
    address public manager;
    address payable[] public players;
    address payable public winner;

    constructor() {
        manager = msg.sender;
    }

    receive() external payable {}

    modifier onlyManager() {
        require(msg.sender == manager, "you're not a manager");
        _;
    }

    function addPlayers() public payable {
        require(msg.value == 1 ether, "Please send 1 ether");
        players.push(payable(msg.sender));
    }

    function getBalance() public view onlyManager returns (uint256) {
        return address(this).balance;
    }

    function random() public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.prevrandao,
                        players.length
                    )
                )
            );
    }

    function pickWinner() public onlyManager {
        require(players.length >= 3, "Not enough players");
        uint r = random();
        uint i = r % players.length;
        winner = players[i];
        winner.transfer(getBalance());
        players = new address payable[](0);
    }

    // this function will give the details of all the players though we have already created a public array of players but this shall give the details while we connect with the front end.
    function allPlayers() public view returns (address payable[] memory) {
        return players;
    }
}
