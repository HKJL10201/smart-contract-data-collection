pragma solidity ^0.4.18;

contract Ownable {

	address public owner;

	function Ownable() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address _owner) onlyOwner public {
		owner = _owner;
	}

}

contract Lottery is Ownable {

	uint public ticketsCapacity;
	uint public ticketPrice;
	uint public jackpot;
	uint public jackpotIncrement;
	uint public smallWinMultiplier;

	uint public jackpotWinnerNumber;

	mapping(uint => address) public tickets;

	function Lottery(uint _ticketsCapacity, uint _ticketPrice,
	    uint _jackpotIncrement, uint _smallWinMultiplier) Ownable() public {

		owner = msg.sender;
		ticketsCapacity = _ticketsCapacity;
		ticketPrice = _ticketPrice * 10**18;
		jackpotIncrement = _jackpotIncrement * 10**18;
		smallWinMultiplier = _smallWinMultiplier;
	}

	function clearTickets() onlyOwner public {
		for(uint i = 1; i <= ticketsCapacity; i++) {
			tickets[i] = 0;
		}
	}

	function buyTicket(uint ticketNumber) payable public {
		require(ticketNumber > 0 && ticketNumber <= ticketsCapacity);
		require(msg.value >= ticketPrice);
		require(tickets[ticketNumber] == 0);

		tickets[ticketNumber] = msg.sender;
		jackpot += jackpotIncrement;

		owner.transfer(ticketPrice / 4);
	}

	function play() onlyOwner public {

		uint smallWinnersCapacity = ticketsCapacity / 100 * 5;
		for(uint i = 1; i <= smallWinnersCapacity; i++) {
			uint smallWinnerNumber = uint(block.blockhash(block.number-1)) % ticketsCapacity + 1;
            address smallWinner = tickets[smallWinnerNumber];
			if(smallWinner != 0) {
			    uint smallWinnerMoney = ticketPrice * smallWinMultiplier;
				smallWinner.transfer(smallWinnerMoney);
			}
		}

		jackpotWinnerNumber = uint(block.blockhash(block.number-1)) % ticketsCapacity + 1;
		address jackpotWinner = tickets[jackpotWinnerNumber];
		if(jackpotWinner != 0) {
		    uint jackpotWinnerMoney = jackpot;
			jackpot = 0;
			jackpotWinner.transfer(jackpotWinnerMoney);
			clearTickets();
		}
	}
}
