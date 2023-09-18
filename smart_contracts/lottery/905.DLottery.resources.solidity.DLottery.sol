pragma solidity ^0.4.11;


contract DLottery {

    // current lotto info
    address[] private empty;
    address[] public owners;
    uint private lotteryEndBlock;
    uint private duration;

    // last lotto
    address private lastWinner; // winner, pot_size, duration
    uint private lastPot;
    uint private lastDuration;
    uint private lastEndBlock;
    uint private allTimeBets;

    uint public test;

    // Contract constructor, called when the contract is deployed
    // When launched, make auctions one day long
    function DLottery() public {
        allTimeBets = 100;
        test = 0;
        lastWinner = 1;
        lastPot = 1;
        lastDuration = 10;
        commenceLottery(10); // 86400 seconds in one day
    }

    // buy tickets when eth received
    function placeBet() public payable {
        checkClosed();
        for (uint i = 0; i < msg.value; i++) {
            owners.push(msg.sender);
            allTimeBets += 1;
        }
    }

    /*
      Interface Functions:
    */
    function getPotSize() public view returns (uint) {
        return owners.length;
    }

    // Called by dapp to check if the auction is over, and
    //  triggers closeLottery if so
    function getBlocksRemaining() public view returns (uint) {
        return lotteryEndBlock - block.number;
    }

    // returns duration of this auction in blocks
    function getDuration() public view returns (uint) {
        return duration;
    }

    function getLastWinner() public view returns (address) {
        return lastWinner;
    }

    function getLastPot() public view returns (uint) {
        return lastPot;
    }

    function getLastDuration() public view returns (uint) {
        return lastDuration;
    }

    function getLastEndBlock() public view returns (uint) {
        return lastEndBlock;
    }

    function getAllTimeBets() public view returns (uint) {
        return allTimeBets;
    }

    // Called when the lottery end event detected
    function closeLottery() private {

        // if participants, get winner and send winnings
        if (owners.length > 0) {
            uint windex = uint(keccak256(block.blockhash(block.number))) % owners.length;
            address winner = owners[windex];

            // update info because lotto closed
            lastWinner = winner;
            lastPot = owners.length;
            lastDuration = duration;
            lastEndBlock = block.number;

            winner.transfer(lastPot); // send ether to winner
        }

        // start new lotto
        commenceLottery(duration);
    }

    function checkClosed() private {
        if (block.number >= lotteryEndBlock) {
            closeLottery();
        }
    }

    // Start lottery in constructor and when each lottery ends
    function commenceLottery(uint durationBlocks) private {
        // reset params
        duration = durationBlocks;
        lotteryEndBlock = block.number + duration;
        owners = empty; // reset owners
    }
}
