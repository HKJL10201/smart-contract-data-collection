pragma solidity 0.7.5;

contract Wallet{
    
    mapping(address => uint)balance;
    
    event AmountDeposited(address sender, uint amount);
    
    function deposit() public payable {
        balance[msg.sender] += msg.value;
        emit AmountDeposited(msg.sender,msg.value);
    }
    
    function withdraw(uint _amount) public {
        require(balance[msg.sender] >= _amount,'Withdrawal is more than a deposit');
        balance[msg.sender] -= _amount;
        msg.sender.transfer(_amount);
    }
    
    function transfer(address payable _recipient, uint _amount) public {
        require(balance[msg.sender] >= _amount,'Transfer is more than a deposit');
        balance[msg.sender] -= _amount;
        _recipient.transfer(_amount);
    }
    
    function getBalance(address _add) view external returns(uint) {
        return balance[_add];
    }
}
