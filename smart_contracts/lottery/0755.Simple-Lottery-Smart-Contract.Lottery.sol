// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.13 and less than 0.9.0
pragma solidity ^0.8.7;

import "github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Lottery is Ownable {
    string[] public users;
    string public winner;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;

    constructor() {
        lottery_state = LOTTERY_STATE.OPEN;
    }

    /**
     * @dev Returns a random number using keccak256
     */
    function random() internal view returns(uint) { 
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)));
    }

    /**
     * @dev Returns the winner of the lottery via a random drawing
     */
    function setWinner() external onlyOwner returns(string memory) {
        require (
            lottery_state == LOTTERY_STATE.OPEN,
            "Looks like you already ran the lottery"
        );
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        uint256 indexOfWinner = random() % users.length;
        winner = users[indexOfWinner];
        lottery_state = LOTTERY_STATE.CLOSED;
        return winner;
    }

    /**
     * @dev Set users equal to any user who has listened to 3 or more episodes a week
     */
    function setUsers(string[] memory newUsers) external onlyOwner {
        require (
            lottery_state == LOTTERY_STATE.OPEN,
            "Looks like you already ran the lottery"
        );
        users = newUsers;
    }
}
