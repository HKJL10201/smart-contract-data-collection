pragma solidity ^0.5.13;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/math/SafeMath.sol";


contract Allowance is Ownable{
    
    
    using SafeMath for uint;
    
    event AllowanceChanged(address _forWho, address _fromWhom, uint _oldAmount, uint _newAmount);
    
    mapping(address => uint) public allowance;
    
    function addAllowance(address _who, uint _amount) public onlyOwner{
        emit AllowanceChanged(_who, msg.sender, allowance[_who], _amount);
        allowance[_who] = _amount;
    }
    
    modifier ownerOrAllowed(uint _amount){
        require(isOwner() || allowance[msg.sender] >= _amount, "You are not allowed");
        _;
    }
    function reduceAllowance(address _who, uint _amount) internal{
        emit AllowanceChanged(_who, msg.sender, allowance[_who], allowance[_who] - _amount);
        allowance[_who] = allowance[_who].sub(_amount);
    }
}


contract SimpleWallet is Allowance {
    
    event MoneySent(address indexed _beneficiary, uint _amount);
    event MoneyRecieved(address indexed _from , uint _amount);

    function withdrawMoney(address payable _to, uint _amount) public ownerOrAllowed(_amount){
        require( _amount <= address(this).balance, "There is not enough balance in the smart contract");
        if(!isOwner()){
            reduceAllowance(msg.sender, _amount);
        }
        emit MoneySent(_to, _amount);
        _to.transfer(_amount);
    }
    
    function renounceOwnership() public onlyOwner{
        revert("Cant renounce OwnerShip");
    }
    
    function () external payable{
        emit MoneyRecieved(msg.sender, msg.value);
    }

}