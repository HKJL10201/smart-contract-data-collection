pragma solidity ^0.4.9;

import "./utils.sol";

contract Lottery
{
    uint256 MAX_LUCKY_NUMBER_VALUE = 100000;
    uint8 OWNER_CUT = 10;
    
    address _owner;
    uint256 _drawDate;
    uint256 _drawnNumber;
    uint256 _ticketCost;
    bool _gameActive;
    mapping (uint256 => address) _tickets;
    
    event NewGameSetEvent(uint256 ticketCost, uint256 drawDate);
    event TicketBoughtEvent(address buyer, uint256 ticketCost, uint256 luckyNumber);
    event OverpayedTicketEvent(address buyer, uint256 valuePayed, uint256 ticketCost);
    event PrizeTransferredEvent();
    
    constructor() public
    {
        _owner = msg.sender;
        _gameActive = false;
    }
    
    function setupGame(uint ticketCost, uint drawDate) public
    {
        require(msg.sender == _owner, "Only the lottery owner can setup games");
        require(_gameActive == false, "A lottery game is currently active");
        require(drawDate > block.timestamp, "Draw date must be in the future");
        
        _drawDate = drawDate;
        _ticketCost = ticketCost;
        _gameActive = true;
        
        emit NewGameSetEvent(_ticketCost, _drawDate);
    }
    
    function drawLuckyNumber() public
    {
        require(msg.sender == _owner, "Only the lottery owner can draw the lucky number");
        require(_gameActive == true, "No game is active at the moment");
        require(now >= _drawDate, "The draw date has not come up yet");
        
        //Draw number and pick winner
        uint256 luckyNumber = Utils.randomGenerator(MAX_LUCKY_NUMBER_VALUE);
        address winner = _tickets[luckyNumber];
        
        //Someone has won the lottery: send the money
        if(winner != 0)
        {
            _owner.transfer(address(this).balance/OWNER_CUT);
            winner.transfer(address(this).balance);
            _gameActive = false;
            emit PrizeTransferredEvent();
        }
        
        //No one has won: delay for a month
        else
            setupGame(_ticketCost, now + 30 days);
    }
    
    function buyTicket(uint256 luckyNumber) public payable
    {
        require(msg.sender != _owner, "Lottery owner cannot buy tickets");
        require(_gameActive == true, "There is no lottery active at the moment");
        require(msg.value >= _ticketCost, "Ticket cost was not reached");
            
        if(msg.value > _ticketCost)
        {
            msg.sender.transfer(msg.value - _ticketCost);
            emit OverpayedTicketEvent(msg.sender, msg.value, _ticketCost);
        }
        
        _tickets[luckyNumber] = msg.sender;
        emit TicketBoughtEvent(msg.sender, _ticketCost, luckyNumber);
    }
    
    function cancelLottery() public
    {
        require(msg.sender == _owner, "Only the lottery owner can destroy it");
        require(_gameActive == false, "There is a game currently active");
        selfdestruct(_owner);
    }
    
    function gameInfo() public view 
    returns(uint256 ticketCost, uint256 drawDate, uint256 prizePool)
    {
        require(_gameActive == true, "There is no game currently active");
        
        return
        (
            _ticketCost,
            _drawDate,
            address(this).balance
        );
    }
}