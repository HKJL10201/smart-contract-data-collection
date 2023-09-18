//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Lottery.sol";

contract Create2Factory {
    address payable[] public players;
    uint256 private startBlock;
    uint256 private endBlock;
    Lottery private loteryTicket;
    Lottery[] public tickets;

    event GameWon(address payable winner);

    function deployGame(
        bytes32 salt,
        uint256 _startBlock,
        uint256 _endBlock
    ) public {
        startBlock = _startBlock;
        endBlock = _endBlock;
        address lotteryContractAddress;

        lotteryContractAddress = Create2.deploy(
            0,
            salt,
            type(Lottery).creationCode
        );

        address newLotteryContractAddress = Clones.clone(
            lotteryContractAddress
        );
        loteryTicket = Lottery(newLotteryContractAddress);
        loteryTicket.initialize();
    }

    function computeAddress(bytes32 salt) public view returns (address) {
        return
            Create2.computeAddress(salt, keccak256(type(Lottery).creationCode));
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function buyTicket() public payable {
        require(msg.value >= .01 ether, "Need at least 0.1 eth");
        require(block.number <= endBlock, "Lottery Ended");

        loteryTicket.safeMint(msg.sender, "metadata.json");

        tickets.push(loteryTicket);

        players.push(payable(msg.sender));
    }

    function getRandomNumber() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(this, block.timestamp)));
    }

    function pickWinner() public {
        uint256 index = getRandomNumber() % players.length;

        players[index].transfer(address(this).balance / 2);

        emit GameWon(players[index]);
    }
}
