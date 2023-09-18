pragma solidity ^0.8.0;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";

contract Lottery is Ownable {
    using SafeBEP20 for IBEP20;
    
    // Variables
    address public lotteryToken;
    uint256 public ticketPrice;
    uint256 public deadline;
    uint256 public lotteryId;
    uint256 public winner;
    mapping(address => uint256) public tickets;
    address[] public participants;
    bool public lotteryClosed;
    
    // Events
    event NewLottery(uint256 indexed lotteryId, uint256 indexed deadline);
    event TicketPurchased(address indexed buyer, uint256 amount);
    event LotteryClosed(uint256 indexed lotteryId, address indexed winner);
    
    // Constructor
    constructor(address _lotteryToken, uint256 _ticketPrice, uint256 _duration) {
        lotteryToken = _lotteryToken;
        ticketPrice = _ticketPrice;
        deadline = block.timestamp + _duration;
        lotteryId = 1;
        lotteryClosed = false;
        emit NewLottery(lotteryId, deadline);
    }
    
    // Functions
    
    // Purchase a lottery ticket
    function purchaseTicket(uint256 amount) public {
        require(!lotteryClosed, "Lottery is closed");
        require(block.timestamp <= deadline, "Lottery has ended");
        
        uint256 cost = amount * ticketPrice;
        IBEP20(lotteryToken).safeTransferFrom(msg.sender, address(this), cost);
        
        // If the user has already purchased tickets, update their ticket count
        if(tickets[msg.sender] > 0) {
            tickets[msg.sender] += amount;
        } else {
            participants.push(msg.sender);
            tickets[msg.sender] = amount;
        }
        
        emit TicketPurchased(msg.sender, amount);
    }
    
    // Draw a winner for the lottery
    function drawWinner() public onlyOwner {
        require(!lotteryClosed, "Lottery is closed");
        require(block.timestamp > deadline, "Lottery has not ended yet");
        
        // Generate a random number between 0 and the number of participants
        uint256 index = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % participants.length;
        winner = index;
        
        // Transfer the prize to the winner
        uint256 prize = IBEP20(lotteryToken).balanceOf(address(this));
        IBEP20(lotteryToken).safeTransfer(participants[winner], prize);
        
        lotteryClosed = true;
        emit LotteryClosed(lotteryId, participants[winner]);
    }
    
    // Get the current list of participants
    function getParticipants() public view returns (address[] memory) {
        return participants;
    }
    
    // Get the number of tickets purchased by a participant
    function getTickets(address participant) public view returns (uint256) {
        return tickets[participant];
    }
    
    // Get the winner of the current lottery
    function getWinner() public view returns (address) {
        return participants[winner];
    }
}
