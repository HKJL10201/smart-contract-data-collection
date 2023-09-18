pragma solidity ^0.4.18;

contract GameLottery {

    struct Ticket {
        address ownerAddress;
        bytes32 hash;
        bool isRevealed;
    }

    uint constant public TICKET_PRICE = 0.01 ether;
    address public winner;
    bytes32 public seed;
    address public manager;

    Ticket[] public revealedTickets;
    mapping(bytes32 => Ticket) public committedTickets;

    uint public ticketDeadline;
    uint public revealDeadline;

    uint public commitDuration;
    uint public revealDuration;
    uint public totalPrize;


    function GameLottery(uint _commitDuration, uint _revealDuration) public {
        commitDuration = _commitDuration;
        revealDuration = _revealDuration;

        ticketDeadline = block.number + commitDuration;
        revealDeadline = ticketDeadline + revealDuration;
        manager = msg.sender;
    }

    function createCommitment(uint secretNumber) public payable {
        require(msg.value == TICKET_PRICE);
        require(block.number <= ticketDeadline);

        bytes32 hash = keccak256(msg.sender, secretNumber);
        Ticket memory ticket = Ticket({
            ownerAddress : msg.sender,
            hash : hash,
            isRevealed : false
            });
        committedTickets[hash] = ticket;

    }


    function reveal(uint secretNumber) public {
        require(block.number > ticketDeadline);
        require(block.number <= revealDeadline);
        bytes32 hash = keccak256(msg.sender, secretNumber);
        Ticket storage ticket = committedTickets[hash];

        require(ticket.ownerAddress != address(0));
        require(ticket.isRevealed == false);

        ticket.isRevealed = true;

        seed = keccak256(seed, secretNumber);
        revealedTickets.push(ticket);
    }

    function drawWinner() public {
        require(block.number > revealDeadline);
        if (revealedTickets.length != 0) {
            uint randIndex = uint(seed) % revealedTickets.length;
            winner = revealedTickets[randIndex].ownerAddress;
            totalPrize = this.balance;
        }

        restart();
    }

    function restart() private {
        ticketDeadline = block.number + commitDuration;
        revealDeadline = ticketDeadline + revealDuration;

        delete revealedTickets;
    }

    function withdrawPrize() public {
        require(msg.sender == winner);
        msg.sender.transfer(totalPrize);
        delete winner;
        delete totalPrize;
    }

    function getRevealedTicket(uint index) public constant returns (address) {
        return revealedTickets[index].ownerAddress;
    }

    function getNumberOfRevealedTickets() public constant returns (uint){
        return revealedTickets.length;
    }
}
