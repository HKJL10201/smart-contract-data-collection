pragma solidity ^0.4.25;


contract Lottery {

    event LotteryTicketPurchased(address indexed _purchaser, uint256 _ticketID);
    event LotteryAmountPaid(address indexed _winner, uint64 _ticketID, uint256 _amount);

    
    uint64 public ticketPrice = 1500000000000000000 wei;
    uint64 public ticketMax = 5;
    address public winnerAddress;


    address[6] public ticketMapping;
    uint256 public ticketsBought = 0;


    modifier allTicketsSold() {
        require(ticketsBought >= ticketMax,"");
        _;
    }


    function() public payable {
        revert("Revert Transaction");
    }

    function buyTicket(uint16 _ticket) public payable returns (bool) {
        require(msg.value == ticketPrice,"Value != Price");
        require(_ticket > 0 && _ticket < ticketMax + 1,"Total tickets exceed Ticket Limit");
        require(ticketMapping[_ticket] == address(0),"Invalid Address");
        require(ticketsBought < ticketMax,"Bought tickets more tham Ticket Limit");

        address purchaser = msg.sender;
        ticketsBought += 1;
        ticketMapping[_ticket] = purchaser;

        if (ticketsBought>=ticketMax) {
            sendReward();
        }

        return true;
    }

   
    function sendReward() public allTicketsSold returns (address) {
        uint64 winningNumber = lotteryPicker();
        address winner = ticketMapping[winningNumber];
        uint256 totalAmount = ticketMax * ticketPrice;


        require(winner != address(0),"Winner cannot be an invalid address");

        winnerAddress = winner; 
        reset();
        winner.transfer(totalAmount);
        
        return winner;
    }


    function lotteryPicker() public view allTicketsSold returns (uint64) {
        bytes memory entropy = abi.encodePacked(block.timestamp, block.number);
        bytes32 hash = sha256(entropy);
        return uint64(hash) % ticketMax;
    }


    function reset() private allTicketsSold returns (bool) {
        ticketsBought = 0;
        for(uint x = 0; x < ticketMax+1; x++) {
            delete ticketMapping[x];
        }
        return true;
    }

    function getTicketsPurchased() public view returns(address[6]) {
        return ticketMapping;
    }
}
