// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    // admin
    address payable public manager;
    // players pool
    address[] public players;
    // winner
    address payable public winner;
    // issue
    uint256 public issue;


    constructor() {
        manager = payable(msg.sender);
    }

    modifier onlyManager {
        require(msg.sender == manager);
        _;
    }

    // Everyone can bet multiple times, but only 1 eth at a time
    function bet() public payable {
        require(msg.value == 1 ether);
        players.push(msg.sender);
    }

    // Find a particularly large random number and take the remainder of the length of our player array
    function draw() onlyManager public {
        bytes memory v1 = abi.encodePacked(
            block.timestamp,
            block.difficulty,
            players.length
        );
        bytes32 v2 = keccak256(v1);
        uint256 v3 = uint256(v2);

        uint256 idx = v3 % players.length;
        uint256 bonus = (address(this).balance * 96) / 100;
        uint256 maintenance = address(this).balance - bonus;

        // Give the winner the bonus
        winner = payable(players[idx]);
        winner.transfer(bonus);
        manager.transfer(maintenance);

        // Clean up
        issue++;
        delete players;
    }

    function refund() onlyManager public {
        for ( uint256 i = 0; i < players.length; i++) {
            payable(players[i]).transfer(1 ether);
        }

        issue++;
        delete players;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function getPlayersCount() public view returns (uint256) {
        return players.length;
    }
}
