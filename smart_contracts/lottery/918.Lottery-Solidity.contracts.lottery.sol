pragma solidity ^0.4.17;

contract Lottery {

    struct ticket {
        address owner;
    }
    mapping (uint => ticket) tickets;
    uint ticketsCount;

    struct round {
        uint endTicketIndex;
        uint blockNumber;
        address winner;
        uint amount;
    }
    mapping(uint => round) public rounds;
    uint public roundsCount;
    
    constructor() public {
        rounds[roundsCount].endTicketIndex = 0;
        roundsCount++;
        rounds[roundsCount].blockNumber = block.number + 40000;
    }
    
    function purchaseTickets(uint _ticketsCount) public payable {
        require(msg.value == 0.01 ether * _ticketsCount, "You did not pay the proper amount. Please try again.");

        for (uint i = 0; i < _ticketsCount; i++) {
            ticketsCount++;
            tickets[ticketsCount].owner = msg.sender;
        }

        rounds[roundsCount].amount += msg.value;
        rounds[roundsCount].endTicketIndex = ticketsCount;
    }
    
    function random() private view returns(uint) {
        uint start = rounds[roundsCount-1].endTicketIndex;
        uint end = rounds[roundsCount].endTicketIndex;
        uint length = end - start;
        require(length > 0, "There are no entries.");

        return (start + 1) + uint8(uint256(keccak256(block.timestamp, block.difficulty))%length);
    }
    
    function pickWinner() public {
        uint index = random();
        
        rounds[roundsCount].winner = tickets[index].owner;

        tickets[index].owner.transfer(this.balance);

        roundsCount++;
        rounds[roundsCount].blockNumber = block.number + 40000;
    }

    function getWinner(uint _roundsCount) public view returns(address) {
        return rounds[_roundsCount].winner;
    }

    function getCurrentRound() public view returns(uint) {
        return roundsCount;
    }

    function getBlockNumber(uint _roundsCount) public view returns(uint) {
        return rounds[_roundsCount].blockNumber;
    }

    function getAmount(uint _roundsCount) public view returns(uint) {
        return rounds[_roundsCount].amount;
    }

    function getTickets(address sender) public view returns(uint) {
        uint start = rounds[roundsCount-1].endTicketIndex + 1;
        uint end = rounds[roundsCount].endTicketIndex;
        uint total;

        for (uint i = start; i <= end; i++) {
            if(tickets[i].owner == sender) {
                total++;
            }
        }

        return total;
    }
    
}