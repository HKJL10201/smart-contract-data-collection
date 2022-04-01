// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract RecurringLottery {
    struct Round {
        uint256 endBlock;
        uint256 drawBlock;
        Entry[] entries;
        uint256 totalQuantity;
        address winner;
    }
    struct Entry {
        address buyer;
        uint256 quantity;
    }

    uint256 public constant TICKET_PRICE = 1e15;
    mapping(uint256 => Round) public rounds;
    uint256 public round;
    uint256 public duration;
    mapping(address => uint256) public balances;

    // duration is in blocks. 1 day = ~5500 blocks
    constructor(uint256 _duration) {
        duration = _duration;
        round = 1;
        // endBlock is the number of blocks that determined the
        // end of a round.
        // drawBlock is 5 blocks after endBlock, used to generate
        // a random seed that determines the entry that gets the prize.
        rounds[round].endBlock = block.number + duration;
        rounds[round].drawBlock = block.number + duration + 5;
    }

    function buy() public payable {
        // msg.value from msg.sender must be a total of units equal to the TICKET_PRICE
        // that is, 5 tickets is [5 * TICKET_PRICE]
        require(msg.value % TICKET_PRICE == 0);

        // starts a new round when current round has ended
        if (block.number > rounds[round].endBlock) {
            round += 1;
            rounds[round].endBlock = block.number + duration;
            rounds[round].drawBlock = block.number + duration + 5;
        }

        uint256 quantity = msg.value / TICKET_PRICE;
        Entry memory entry = Entry(msg.sender, quantity);
        rounds[round].entries.push(entry);
        rounds[round].totalQuantity += quantity;
    }

    function drawWinner(uint256 roundNumber) public {
        // pick a round
        Round storage drawing = rounds[roundNumber];
        require(drawing.winner == address(0));
        require(block.number > drawing.drawBlock);
        require(drawing.entries.length > 0);

        // pick winner
        bytes32 rand = keccak256(abi.encode(drawing.drawBlock));
        uint256 counter = uint256(rand) % drawing.totalQuantity;

        for (uint256 i = 0; i < drawing.entries.length; i++) {
            uint256 quantity = drawing.entries[i].quantity;

            if (quantity > counter) {
                drawing.winner = drawing.entries[i].buyer;
                break;
            } else counter -= quantity;
        }
        
        balances[drawing.winner] += TICKET_PRICE * drawing.totalQuantity;
    }

    function withdraw() public {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function deleteRound(uint256 _round) public {
        require(block.number > rounds[_round].drawBlock + 100);
        require(rounds[_round].winner != address(0));
        delete rounds[_round];
    }

    receive() external payable {
        buy();
    }
}
