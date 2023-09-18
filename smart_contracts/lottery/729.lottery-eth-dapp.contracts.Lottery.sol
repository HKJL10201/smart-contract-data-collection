// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery  is Ownable {

    address public _owner;
    address public winner;
    uint256 public expiration; 
    
    uint public players;
    uint public numberOfTickets;

    mapping(uint => address) public ticketToOwner;
    mapping(address => uint) public ownerTicketsCount;
    mapping(address => uint[]) public ownerToTickets;


    uint  constant public _ticketPrice = 1e9 gwei;
    uint public totalPrize;
    
    bool ended;
    
    event PaymentReceived(address from, uint256 amount);
    event LotteryEnded(address _winner, uint prize);
    event TicketSold(address buyer, uint ticketId);
    
    error LotteryNotYetEnded();
    error LotteryEndAlreadyCalled();
    error LotteryAlreadyEnded();
    
   
    constructor(uint duration) {
         _owner = msg.sender;
         expiration = block.timestamp + duration;
         
    }

    function showMyTickets(address user) external view returns (uint[] memory) {
        require(msg.sender == user|| msg.sender == _owner);

        return ownerToTickets[user];
    }

   
    function buyTicket() external payable {
        require(msg.value == _ticketPrice,  "Price per ticket is 1 ether");
        emit PaymentReceived(msg.sender, msg.value);
        totalPrize = address(this).balance;
        
        if (block.timestamp > expiration) {
            revert LotteryAlreadyEnded();
        }
        
        if (ownerTicketsCount[msg.sender] == 0) {
            ownerTicketsCount[msg.sender] = 1;
            players++;
        } else {
            ownerTicketsCount[msg.sender]++;
        }
        
        uint newTicket = _generateTicket();
        ticketToOwner[newTicket] = msg.sender;
        ownerToTickets[msg.sender].push(newTicket); 
        emit TicketSold(msg.sender, newTicket);
    }
    
    
    function lotteryEnd() external onlyOwner {
        if (block.timestamp < expiration) {
            revert LotteryNotYetEnded();
        }
        if (ended) {
            revert LotteryEndAlreadyCalled();
        }
        winner = _chooseWinner();
        _payWinner();
        
        emit LotteryEnded(winner, totalPrize);
    }


    function _generateTicket() private returns (uint) {
        uint _ticketId = numberOfTickets + 1;
        numberOfTickets++;
        return _ticketId;
    }
    
    function _random() private view returns (uint) {
        return (uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % numberOfTickets) + 1;
    }
    
    function _chooseWinner() private returns (address) {
        uint winningTicket = _random();
        winner = ticketToOwner[winningTicket];
        return winner;
    }
    
    function _payWinner()  private {
        payable(winner).transfer(totalPrize);
    
    }

    
}