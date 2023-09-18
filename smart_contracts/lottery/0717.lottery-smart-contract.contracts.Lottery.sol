pragma solidity ^0.8.18;

contract Lottery {
    address payable[] public players;
    address public manager;
    uint public minimumBet;
    uint public randomSeed;
    uint public winningIndex;
    uint public startTime;

    constructor(uint _minimumBet) {
        manager = msg.sender;
        minimumBet = _minimumBet;
        startTime = block.timestamp;
    }

    function enter() public payable {
        require(msg.value >= minimumBet, "Minimum bet not met.");
        players.push(payable(msg.sender));
    }

    function selectWinner() public restricted {
        require(players.length > 0, "No players entered.");

        // pick a random winner
        winningIndex = generateRandomNumber(players.length);

        // transfer the winnings to the winner
        players[winningIndex].transfer(address(this).balance);

        // reset the game
        players = new address payable[](0);
        startTime = 0;
    }

    function generateRandomNumber(
        uint256 upperLimit
    ) private view returns (uint256) {
        bytes32 seed = 0;
        while (seed == 0) {
            seed = generateSeed();
        }
        return uint256(seed) % upperLimit;
    }

    function generateSeed() private view returns (bytes32) {
        require(startTime > 0, "Lottery has not started yet");

        uint256 blockDelta = block.timestamp - startTime;

        // ensure blocktime isn't the same
        if (blockDelta == 0) {
            return 0;
        }

        return keccak256(abi.encodePacked(blockDelta));
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    modifier restricted() {
        require(
            msg.sender == manager,
            "Only the manager can perform this action."
        );
        _;
    }
}
