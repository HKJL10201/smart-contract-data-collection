pragma solidity >=0.4.22 <0.6.0;

import "./betting.sol";

contract bettingMarket {
    
    struct Bet {
        uint betId;
        address seller;
        Betting betContract;
        string assertion;
        bool outcome;
        uint winnerEarnings;
        uint price;
        bool sold;
    }
   
    uint numBets;
    
    mapping (uint => Bet) bets;
    mapping (address => uint) public balance;
    
    // Sell bet on the market, specify the address of the deployed Betting contract
    function sellBet(address payable _contractAddress, uint _price) public returns (uint) {
        Betting bc = Betting(_contractAddress);
        require(bc.checkEarnings(msg.sender) > 0);
        Bet memory b = Bet(
            numBets,
            msg.sender, 
            bc, 
            bc.assertion(), 
            bc.checkBet(msg.sender), 
            bc.winnerEarnings(), 
            _price, 
            false
        );
        bets[numBets] = b;
        numBets++;
        return b.betId;
    }
    
    //Payable function to buy a bet from the market
    function buyBet(uint _betId) public payable {
        Bet memory b = bets[_betId];
        require(!b.sold || msg.value >= b.price);
        if (msg.value > b.price) {
            msg.sender.transfer(msg.value - b.price);
        }
        b.betContract.marketTransfer(b.seller, msg.sender);
        balance[b.seller] += b.price;
        b.sold = true;
    }
    
    // Withdraw funds from contract after bet is sold
    function withdraw() public {
        msg.sender.transfer(balance[msg.sender]);
    }
    
    /*
    View functions: allows potential buyers to access the attributes of a 
    bet using its betId
    */
    
    function checkAssertion(uint _betId) public view returns(string memory) {
        return bets[_betId].assertion;
    }
    
    function checkOutcome(uint _betId) public view returns(bool) {
        return bets[_betId].outcome;
    }
    
    function checkWinnerEarnings(uint _betId) public view returns(uint) {
        return bets[_betId].winnerEarnings;
    }
    
    function checkPrice(uint _betId) public view returns(uint) {
        return bets[_betId].price;
    }
    
}
    
    
