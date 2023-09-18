// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery {
    address public lotteryManager;
    address payable[] public participants;

    constructor() {
        lotteryManager = msg.sender;
    }

    function enterLottery() public payable {
        require(msg.value >= 0.01 ether);
        participants.push(payable(msg.sender));
        // participants.push(payable(senderAddress));
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        participants
                    )
                )
            );
    }

    function pickWinner() public {
        require(msg.sender == lotteryManager);
        // require(senderAddress == lotteryManager);
        uint256 index = random() % participants.length;
        participants[index].transfer(address(this).balance);
        participants = new address payable[](0);
    }
}
