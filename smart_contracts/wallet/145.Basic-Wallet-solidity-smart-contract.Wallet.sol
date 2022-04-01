pragma solidity ^0.5.0;

contract my_wallet
{
    mapping(address => uint) public balances;
    address payable wallet;
    event purchase(address _buyer, uint _amount);
    
    function buy_token() public payable
    {
        balances[msg.sender] += 1;
        wallet.transfer(msg.value);
        emit purchase(msg.sender,1);
    }
    
    constructor(address payable _wallet) public
    {
        wallet = _wallet;
    }
}
