pragma solidity 0.8.12;

contract Lottery {
    address payable[] public players;
    address public manager;

    constructor() {
        manager = msg.sender;
    }

    receive() external payable {
        require(
            msg.value == 0.1 ether,
            "Invalid Value received, Expected 0.1 Ether"
        );
        players.push(payable(msg.sender));
    }

    // Shows the balance for the contract address
    function getBalance() public view returns (uint256) {
        require(msg.sender == manager, "Only manager can view the balance");
        return address(this).balance;
    }

    function random() public view returns (uint256) {
        bytes32 value = keccak256(
            abi.encodePacked(block.difficulty, block.timestamp, players.length)
        );
        return uint256(value);
    }

    // Transfers all the balance to the winner
    function selectWinner() public {
        require(
            msg.sender == manager,
            "Only manager can start the winning process"
        );
        require(
            players.length >= 3,
            "Not enough players to conduct the lottery, Atleast 3 are needed"
        );

        uint256 r = random();
        uint256 index = r % players.length;
        address payable winner;

        winner = players[index];
        winner.transfer(getBalance());

        // as the money tranferred to winner, resetting the lottery
        players = new address payable[](0);
    }
}
