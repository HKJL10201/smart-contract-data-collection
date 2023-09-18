//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Lottery {
    address payable[] public players;
    address manager; //change
    address payable public winner; //new change

    constructor() {
        manager = msg.sender;
    }

    receive() external payable {
        require(msg.value == 0.1 ether, "Please pay 0.1 ether only"); //change
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns (uint256) {
        require(msg.sender == manager, "You are not the manager"); //change
        return address(this).balance;
    }

    function random() internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        players.length
                    )
                )
            );
    }

    function pickWinner() public {
        //change
        require(msg.sender == manager, "You are not the manager"); //change
        require(players.length >= 3, "Players are less than 3"); //change

        uint256 r = random();

        uint256 index = r % players.length;

        winner = players[index];

        winner.transfer(getBalance());

        players = new address payable[](0);
    }
}
