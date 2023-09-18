// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

contract Lottery {
    address public manager;
    //address public winner;
    address payable[] public players;

    constructor() {
        //User that calls that contract becomes the owner/manager
        manager = msg.sender;
    }

    function enter() public payable {
        //minimum value of ether to send to participate in lottery
        require(
            msg.value > 0.01 ether,
            "A minimum of 0.01 ether must be sent to participate in the lottery!"
        );
        //adding players who fulfill the criteria in the people array
        players.push(payable(msg.sender));
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
        uint256 index = random() % players.length;
        address contractAddress = address(this);
        //player who wins gets all the contest money transferred to them
        // address winnerAddress = players[index];
        // winner = players[index];
        players[index].transfer(contractAddress.balance);
        //New dynamic array after a contract has run once so that this clears the array of existing players and can run as soon as one lottery ends.
        players = new address payable[](0);
    }

    function getPlayers() public view returns (address payable[] memory) {
        //return list of participating
        return players;
    }

    modifier restricted() {
        require(
            msg.sender == manager,
            "Only owner/manager can call this function"
        );
        _;
    }
}
