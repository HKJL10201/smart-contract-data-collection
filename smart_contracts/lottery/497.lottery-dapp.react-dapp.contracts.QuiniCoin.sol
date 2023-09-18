//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC20.sol";

contract QuiniCoin {
    // Opening statements
    ERC20 private token;
    address payable public owner;
    address public _contract;
    uint public createdTokens = 10000;

    event purchasedTokens(uint, address);

    constructor() {
        token = new ERC20(createdTokens);
        owner = payable(msg.sender);
        _contract = address(this);
    }

    // Token management
    function tokenPrice(uint _tokenQty) internal pure returns(uint) {
        return _tokenQty*(1 ether);
    }

    function generateTokens(uint _tokenQty) public Lottery(msg.sender) {
        token.increaseTotalSupply(_tokenQty);
    }

    modifier Lottery(address _address) {
        require(_address==owner, "You don't have the permissions to execute this function");
        _;
    }

    function buyToken(uint _tokenQty) public payable {
        uint cost = tokenPrice(_tokenQty);
        require(msg.value>=cost, "You do not have the amount of ethers necessary for the purchase.");
        uint returnValue = msg.value-cost;
        payable(msg.sender).transfer(returnValue);
        uint balance = balanceOf();
        require(_tokenQty<=balance, "The number of tokens requested exceeds the number of tokens for sale.");
        token.transfer(msg.sender, _tokenQty);
        emit purchasedTokens(_tokenQty, msg.sender);
    }

    function balanceOf() public view returns(uint) {
        return token.balanceOf(address(this));
    }

    function getJackpot() public view returns(uint) {
        return token.balanceOf(owner);
    }

    function myTokens() public view returns(uint) {
        return token.balanceOf(msg.sender);
    }

    // Lottery management
    uint public ticketPrice = 5;
    mapping(address=>uint[]) peopleTickets;
    mapping (uint=>address) winner;
    uint randNonce = 0;
    uint[] purchasedTickets;
    event purchasedTicket(uint, address);
    event winningTicket(uint);
    event swapedTokens(uint, address);

    function buyTicket(uint _tickets) public {
        uint totalPrice = _tickets*ticketPrice;
        require(totalPrice<=myTokens(), "You need to buy more tokens.");
        token.transferToLottery(msg.sender, owner, totalPrice);
        for(uint i=0; i<_tickets; i++) {
            uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce)))%10000;
            randNonce++;
            peopleTickets[msg.sender].push(random);
            purchasedTickets.push(random);
            winner[random] = msg.sender;
            emit purchasedTicket(random, msg.sender);
        }
    }

    function myTickets() public view returns(uint[] memory) {
        return peopleTickets[msg.sender];
    }

    function generateWinningTicket() public Lottery(msg.sender) {
        uint ticketsQty = purchasedTickets.length;
        require(ticketsQty>0, "No ticket has been purchased.");
        uint randomIndex = uint(uint(keccak256(abi.encodePacked(block.timestamp)))%ticketsQty);
        uint winning = purchasedTickets[randomIndex];
        emit winningTicket(winning);
        address winnerAddress = winner[winning];
        token.transferToLottery(msg.sender, winnerAddress, getJackpot());
    }

    function swapTokens(uint _tokens) public payable {
        require(_tokens>0, "The number of tokens must be greater than 0.");
        require(_tokens<=myTokens(), "You do not have the amount of tokens you want to exchange.");
        token.transferToLottery(msg.sender, address(this), _tokens);
        payable(msg.sender).transfer(tokenPrice(_tokens));
        emit swapedTokens(_tokens, msg.sender);
    }
}