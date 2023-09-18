// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

error Lottery_LowEntryAmount();

contract Lottery {
    //Variables
    uint256 private immutable i_entryPrice;
    address payable[] private s_participantsAddress;

    constructor(uint256 entryPrice) {
        i_entryPrice = entryPrice;
    }

    function EnterLottery() public payable {
        if (msg.value < i_entryPrice) {
            revert Lottery_LowEntryAmount();
        }

        s_participantsAddress.push(payable(msg.sender));
    }
}
