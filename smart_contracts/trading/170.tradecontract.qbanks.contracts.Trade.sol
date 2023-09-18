pragma solidity 0.8.6;

contract TradeImpl{
    
    uint public tradeId;
    address public fromParty;
    address public toParty;
    uint public amount;
    uint public tradeDate;
    
    function addTrade(uint _tradeId, address _fromParty, address _toParty, uint _amount, uint _tradeDate) public {
        tradeId = _tradeId;
        fromParty = _fromParty;
        toParty = _toParty;
        amount = _amount;
        tradeDate = _tradeDate;
    }
    
    function getTrade() view public returns(address, address, uint, uint){
        return(fromParty, toParty, amount, tradeDate);
    }
}