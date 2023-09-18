// SPDX-License-Identifier: GPL-3.0
pragma solidity  ^0.8.1;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract Allowance is Ownable{
    
    using SafeMath for uint;

    function isOwner() 
        public view returns(bool)
    {
        return 
        owner() == msg.sender;
    
    }
    
    function RenounceOwnership() 
        public view onlyOwner 
    {
        revert("can't renounceOwnership here");
    
    }
    
    mapping (address=>uint) public allowance;

    event AllowanceChanged(
        address indexed _forWho,
        address indexed _byWhom,
        uint _oldAmount, 
        uint _newAmount);
    
    function addAllowance(
        address _MyAddress, 
        uint _Amount) 
        public onlyOwner{
    
        emit AllowanceChanged(
            _MyAddress,
            msg.sender,
            allowance[_MyAddress],
            _Amount);
            allowance[_MyAddress] =_Amount;
    
    }
    
    modifier OwnerOrAllowed(uint _amount) {
        require(isOwner() || allowance[msg.sender] >= _amount,
        "not enough balance");
    _;
    
    } 
    
    function ReduceAllowanceLimit(
        address _whose, 
        uint _amount) 
        public onlyOwner 
    {  
        emit AllowanceChanged(
            _whose,
            msg.sender, 
            allowance[_whose],
            allowance[_whose].sub(_amount));

        allowance[_whose]=allowance[_whose].sub(_amount); 
    }
}

contract SharedWallet is Allowance{

    event sendMoney(
        address indexed _beneficiary, 
        uint amount);
    
    event receivedMoney(
        address indexed _from,
        uint amount);

    function WithdrawAllMoney(
        address payable _to , 
        uint _amount) 
        public 
        OwnerOrAllowed (_amount) 
    { 
        require(_amount<=address(this).balance, 
            "not enough balance in contract");// to set error if not enough balance 
        
        if(!isOwner())
        {
            ReduceAllowanceLimit(
                msg.sender,
                 _amount);
        }

        emit sendMoney(
            _to,
            _amount);
            _to.transfer(_amount);
    
    }
    
    fallback() external payable{
    
        emit receivedMoney(msg.sender, msg.value);
    }

    receive() external payable{
    
        emit receivedMoney(msg.sender, msg.value);
    }
}

