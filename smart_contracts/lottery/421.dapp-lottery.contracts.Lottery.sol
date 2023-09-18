//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Lottery {
    address payable[] public players;                                           //adding address of all players inside players array
    address public manager;                                                     

    constructor() {
        manager = msg.sender;                                                   // address of the contract owner
    }

    receive() external payable {
        require(msg.value == 0.1 ether);                                        // min value required to participate in lottery
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns (uint256) {
        require(msg.sender == manager, "You are not the manager");
        return address(this).balance;
    }

    // Generating a truly random number using keccak256 algorithm
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
        require(msg.sender == manager);
        require(players.length >= 3);
        uint256 r = random();
        address payable winner;
        uint256 index = r % players.length;

        winner = players[index];
        winner.transfer(getBalance());
        players = new address payable[](0);
    }
}
