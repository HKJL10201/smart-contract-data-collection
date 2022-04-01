//SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import 'https://github.com/Urubit/urubit.sol/blob/main/Urubit.sol';

//////////////////////////////
//                          //
//  URUBITLOTTERY Project   //
//                          //            
//////////////////////////////

// Made in Uruguay

abstract contract _Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract _Ownable is _Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract URUBLottery is Ownable {

	mapping (address => uint256) public winnings;
	address[] public tickets;
	
	address public burnAddress = 0x0000000000000000000000000000000000000001;
	address public feeAddress = 0xE6882c262ff1f9aCF98463045b30362493ddCD44;
	
	uint256 public burnFee = 15;
	uint256 public buyFee = 5;
	
	string public name = "Urubit Lottery";
    string public symbol = "URUBL";
    
    uint256 public ticketCost = 10000000000;
    //uint256 public maxTickets = 10;
    //uint256 public remainingTickets = 0;
    uint public ticketCount = 0;
    uint256 public randomNum = 0;
    address public latestWinner;
    
    // Constructor
    constructor ()
    {
	    //remainingTickets = maxTickets;
    }
    
    // Buy tickets (price is defined by ticketCost)
    function Buy(uint256 quantity) public payable {
        
        require(quantity > 0);
        //require(ticketCount + quantity <= maxTickets);
        
        // Connect with URUBit contract to make transaction after approval
        IERC20 urubit = IERC20(address(0xf8759DE7F2C8d3F32Fd8f8e4c0C02D436a05DdEb));
        require(urubit.transferFrom(msg.sender, address(this), ticketCost * quantity));
	    
	    //remainingTickets -= quantity;
	    
	    for (uint i = 0; i < quantity; i++)
        {
	        tickets.push(msg.sender);
        }
        
	    ticketCount += quantity;
    }
    
    // Withdraw prizes
    function Withdraw() public 
    {
        require(winnings[msg.sender] > 0);
        
        uint256 amountToWithdraw = winnings[msg.sender];
        
        winnings[msg.sender] = 0;
        
        //msg.sender.transfer(amountToWithdraw);
        
        IERC20 urubit = IERC20(address(0xf8759DE7F2C8d3F32Fd8f8e4c0C02D436a05DdEb));
        require(urubit.transfer(msg.sender, amountToWithdraw));
    }
    
    function getPrizeAmountUrubit() view public returns(uint256)
    {
        uint256 prizePool = ticketCount;
        uint256 prizePoolUrubit = prizePool * ticketCost;
        return prizePoolUrubit / 100000000;
    }
    
    function getLatestWinner() view public returns(address)
    {
        return latestWinner;
    }
    
    /*function getMaxTickets() view public returns(uint256)
    {
        return maxTickets;
    }*/
    
    function getLatestRandomNum() view public returns(uint256)
    {
        return randomNum;
    }
    
    /*function getRemainingTickets() view public returns(uint256)
    {
        return remainingTickets;
    }*/
    
    function getTicketCount() view public returns(uint)
    {
        return ticketCount;
    }
    
    function getTicketsPrice(uint _amount) view public returns(uint)
    {
        return _amount * ticketCost / 100000000;
    }
    
    function getAddressTicketCount(address _address) view public returns(uint256)
    {
        uint256 _ticketAmount = 0;
        
        for (uint i = 0; i < tickets.length; i++)
        {
	        if(tickets[i] == _address)
	        {
	            _ticketAmount++;
	        }
        }
        
        return _ticketAmount;
    }
    
    function getAddressPrize(address _address) view public returns(uint256)
    {
        uint256 prizeAmount = winnings[_address] / 100000000;
        return prizeAmount;
    }
    
    function getTicketCost() view public returns(uint)
    {
        return ticketCost;
    }
    

    /*function setMaxTickets(uint256 maximumTickets) public onlyOwner()
    {
        maxTickets = maximumTickets;
    }*/
    
    // Sets tickets value
    function setTicketCost(uint256 _ticketCost) public onlyOwner()
    {
        // Can't change ticketValue when a lottery is already started
        require(ticketCount == 0);
        
        ticketCost = _ticketCost;
    }
    
    function setBurnFee(uint256 _burnFee) public onlyOwner()
    {
        burnFee = _burnFee;
    }
    
    function setBuyFee(uint256 _buyFee) public onlyOwner()
    {
        buyFee = _buyFee;
    }
    
    function setFeeAddress(address _feeAddress) public onlyOwner()
    {
        feeAddress = _feeAddress;
    }
    
    // Choose a random winner ticket
    function chooseWinner() public onlyOwner() 
    {
        uint256 totalFees = burnFee + buyFee;
        uint256 rewardPercentage = 100 - totalFees;
        
        randomNum = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % ticketCount;
        
        latestWinner = tickets[randomNum];
        
        uint256 prize = ticketCount * ticketCost / 100 * rewardPercentage;
        uint256 burnAmount = ticketCount * ticketCost / 100 * burnFee;
        uint256 feeAmount = ticketCount * ticketCost / 100 * buyFee;
        
        IERC20 urubit = IERC20(address(0xf8759DE7F2C8d3F32Fd8f8e4c0C02D436a05DdEb));
        
        urubit.transfer(burnAddress, burnAmount);
        urubit.transfer(feeAddress, feeAmount);
        
        winnings[latestWinner] += prize;
        ticketCount = 0;
        //remainingTickets = maxTickets;
        
        delete tickets;
    }
}
