pragma solidity >0.6.0;

contract Lottery {

    uint constant TICKET_PRICE = 1 ether;
    uint ticketingCloses;

    address[] tickets;
    address payable winner;

    constructor (uint duration) public {
        ticketingCloses = block.timestamp + duration;
    }
    
    // Use this function to buy a ticket
    function buyTicket (address buyerAddress) payable public {
	    require(msg.value >= TICKET_PRICE);

        addTicketAddress(buyerAddress);
    }

    function addTicketAddress (address addressNumber) public {
        tickets.push(addressNumber);
    }

    function getTicketAddress () public view returns (address[] memory addresses) {
        addresses = tickets;
    }

    function random(uint seed) public pure returns (uint) {  
        return uint(keccak256(abi.encodePacked(seed)));
    } //use case : random(0x7543def) % 100;

    function drawWinner () public {
	    require(block.timestamp > ticketingCloses + 5 seconds);
	    require(winner == address(0));

	    bytes32 seed = keccak256(abi.encodePacked(blockhash(block.number-1)));
	    winner = payable(tickets[random(uint(seed)) % tickets.length]);

        // sendWinnerPrice();
    }

    function checkIfWin (address ticketAddress) public view returns (bool) {
        return (winner == ticketAddress ? true : false);
    }

    function sendWinnerPrice () payable public {
	    require(winner != address(0));
        
        payable(winner).transfer(address(this).balance);
    }

}