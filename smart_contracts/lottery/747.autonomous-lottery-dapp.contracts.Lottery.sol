//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "hardhat/console.sol";

contract Lottery {
    uint256[] public rounds;
    address[][] public players;
    uint256[] public payouts;

    uint256 public roundDurationInBlocks = 10;

    event NewPlayer(uint256 roundStartingBlock, address indexed player, uint256 value);

    event Withdrawal(uint256 roundStartingBlock, address indexed winner, uint256 value);

    modifier onlyFinishedRound(uint256 roundIndex) {
        uint256 roundStartingBlock = rounds[roundIndex];
        uint256 currentRoundStartingBlock = getCurrentRoundStartingBlock();
        require(
            roundStartingBlock < currentRoundStartingBlock,
            "Round not finished yet"
        );
        _;
    }

    function enterCurrentRound() external payable {
        require(msg.value >= 0.01 ether, "Minimum bet value is 0.01 ether");
        uint256 currentRoundStartingBlock = getCurrentRoundStartingBlock();
        if (
            rounds.length == 0 ||
            rounds[rounds.length - 1] != currentRoundStartingBlock
        ) {
            rounds.push(currentRoundStartingBlock);
            players.push([msg.sender]);
            payouts.push(msg.value);
        } else {
            players[players.length - 1].push(msg.sender);
            payouts[payouts.length - 1] += msg.value;
        }
        emit NewPlayer(rounds[rounds.length - 1], msg.sender, msg.value);
    }

    function getRounds() external view returns (uint256[] memory) {
        return rounds;
    }

    function getPlayers() external view returns (address[][] memory) {
        return players;
    }

    function getPayouts() external view returns (uint256[] memory) {
        return payouts;
    }

    function withdrawPayout(uint256 roundIndex)
        external
        onlyFinishedRound(roundIndex)
    {
        uint256 payout = payouts[roundIndex];
        require(payout > 0, "Payout has already been withdrawn for this round");
        address payable winner = payable(getWinner(roundIndex));
        payouts[roundIndex] = 0;
        uint256 balanceBeforeTransfer = address(this).balance;
        winner.transfer(payout);
        assert(address(this).balance == balanceBeforeTransfer - payout);
        emit Withdrawal(rounds[rounds.length - 1], winner, payout);
    }

    function getWinner(uint256 roundIndex) public view returns (address) {
        bytes32 pseudoRandom;
        for (uint256 i = 0; i < players[roundIndex].length; i++) {
            pseudoRandom = keccak256(
                abi.encodePacked(players[roundIndex], pseudoRandom)
            );
        }
        uint256 winnerIndex = uint256(pseudoRandom) %
            players[roundIndex].length;
        return players[roundIndex][winnerIndex];
    }

    function getCurrentRoundStartingBlock() internal view returns (uint256) {
        return (block.number / roundDurationInBlocks) * roundDurationInBlocks;
    }
}
