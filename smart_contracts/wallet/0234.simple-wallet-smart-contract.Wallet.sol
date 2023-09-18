// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "./Allownace.sol";
 
contract Allowance is Ownable {
    
    event AllowanceChanged(address indexed _forWho, address _fromWhom, uint _oldAmount, uint _newAmount);
    
    mapping(address => uint) public allowance;
    
    function addAllowance(address _who, uint _amount) public onlyOwner{
        // here the msg.sender is the owner who deployed the smart contract
        emit AllowanceChanged(_who, msg.sender, allowance[_who], _amount);
        allowance[_who] = _amount;
    }
    
    function isOwner() public view returns (bool) {
        return owner() == _msgSender();
    }
    
    modifier ownerOrAllowed(uint _amount) {
        require(isOwner()|| allowance[msg.sender] >= _amount, "You are not allowed");
        _;
    }
    
    function reduceAllownance(address _who, address _to, uint _amount) internal {
        // here msg.sender is the allownce address, _who can be the allowance address
        // or another address
        emit AllowanceChanged(_who, _to, allowance[_who], allowance[_who] - _amount);
        allowance[_who] -= _amount;
    }
}

contract SimpleWallet is Allowance  {
    
    event RecieveLog(address _addr, uint _amount);
    
    event MoneySent(address indexed _to, uint _amount);
    
    event MoneyReceived(address indexed _from, uint _amount);

    function withdrawMoney(address payable _to, uint _amount) public ownerOrAllowed(_amount)  {
        require(_amount <= address(this).balance, "Not enough fund in the smart contract");
        if(!isOwner()){
            reduceAllownance(msg.sender, _to, _amount);
        }
        emit MoneySent(_to, _amount);
        _to.transfer(_amount);
    }
    
    function renounceOwnership() public view onlyOwner override(Ownable) {
        revert("Cannot renounce ownership!");
    }
    
    fallback() external payable {
        // does nothing
    }
    
     receive() external payable {
        emit MoneyReceived(msg.sender, msg.value);
    }
}