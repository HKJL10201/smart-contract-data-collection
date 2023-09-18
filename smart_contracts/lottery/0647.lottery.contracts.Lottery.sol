//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is Ownable {
    mapping(address => uint256) public players;
    address payable[] public playersList;
    address payable public winner;
    uint256 public bidAmount;

    event WinnerFound(address lotteryWinner, uint256 prize);

    constructor(uint256 desiredBid) {
        bidAmount = desiredBid;
    }

    modifier bouncer() {
        require(players[msg.sender] == 0, "Already joined the lottery");
        require(msg.value == bidAmount, "Incorrect bid to join the lottery");
        _;
    }

    function joinLottery() public payable bouncer {
        playersList.push(payable(msg.sender));
        players[msg.sender] = 1;
    }

    function pickWinner() public onlyOwner {
        winner = playersList[getRandomNumber()];
        uint256 prize = address(this).balance;
        (bool success, ) = winner.call{value: prize}("");
        require(success == true, "Transfer failed");
        resetPlayersMapping();
        delete playersList;
        emit WinnerFound(winner, prize);
    }

    function modifyRequiredBid(uint256 updatedBid) public onlyOwner {
        bidAmount = updatedBid;
    }

    // This is not a production ready way of finding a random number
    // Check Chainlink VRF for a secure randomness generator: https://docs.chain.link/docs/chainlink-vrf/
    function getRandomNumber() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        playersList
                    )
                )
            ) % playersList.length;
    }

    function resetPlayersMapping() private {
        for (uint256 i = 0; i < playersList.length; i++) {
            delete players[playersList[i]];
        }
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}

    fallback() external {}
}
