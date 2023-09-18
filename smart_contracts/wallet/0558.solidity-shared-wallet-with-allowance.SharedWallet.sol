pragma solidity ^0.8.7;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Allowance is Ownable {
    mapping(address => uint) public allowance;
    
    event AllowanceChanged(address indexed _byAddress, address indexed _forAddress, uint _oldAllowance, uint _newAllowance);
    
    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }
    
    function setAllowance(address _address, uint _allowance) public onlyOwner {
        emit AllowanceChanged(msg.sender, _address, allowance[_address], _allowance);
        allowance[_address] = _allowance;
    }
}

contract SharedWallet is Allowance {
    uint public walletBalance;
    
    event MoneySent(address indexed _to, uint _amount);
    event MoneyReceived(address indexed _from, uint _amount);
    
    function renounceOwnership() public override onlyOwner {
        revert("You can't renounce ownership");
    }
    
    function withdrawAll() public onlyOwner {
        emit MoneySent(msg.sender, address(this).balance);
        walletBalance = 0;
        payable(owner()).transfer(address(this).balance);
    }
    
    function withdraw(uint _amount) public {
        require(_amount <= allowance[msg.sender] || isOwner(), "Not enough allowance");
        emit MoneySent(msg.sender, _amount);
        walletBalance -= _amount;
        if (!isOwner()) {
            emit AllowanceChanged(msg.sender, msg.sender, allowance[msg.sender], allowance[msg.sender] - _amount);
            allowance[msg.sender] -= _amount;
        }
        payable(msg.sender).transfer(_amount);
    }
    
    receive() external payable {
        assert(walletBalance + msg.value >= walletBalance);
        emit MoneyReceived(msg.sender, msg.value);
        walletBalance += msg.value;
    }
}
