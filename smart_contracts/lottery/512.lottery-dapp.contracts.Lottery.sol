// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract Lottery {
    event Deposit(address indexed depositor, uint256 amount);
    event Winner(address indexed winner);
    address[] private _participants;
    mapping(address => uint256) public winners;
    uint256 public nextLotteryPrice;
    uint256 public lotteryPrice = 1 ether;

    function join() external payable {
        require(msg.value == 1 ether, "Minimum transfer 1 Eth");
        _participants.push(msg.sender);
        nextLotteryPrice += 1 ether;
        emit Deposit(msg.sender, msg.value);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function participants() external view returns (address[] memory) {
        return _participants;
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        _participants.length
                    )
                )
            );
    }

    // function participantCount() internal view returns (uint256) {
    //     return participants.length;
    // }

    function selectWinner() public {
        require(_participants.length >= 3, "Min participants should be 3");
        address winner = _participants[random() % _participants.length];
        emit Winner(winner);
        winners[winner] += nextLotteryPrice;
        delete nextLotteryPrice;
        delete _participants;
    }

    function claim() external {
        uint256 claimableAmount = winners[msg.sender];
        require(claimableAmount > 0, "We owe you nothing!");
        winners[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: claimableAmount}("");
        require(success, "Ether transfer failed");
    }
}
