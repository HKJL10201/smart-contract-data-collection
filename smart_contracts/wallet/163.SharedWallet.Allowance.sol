pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";

contract Allowance is Ownable {
    using SafeMath for uint256;
    
    event AllowanceChanged(address indexed _dependant, uint256 _allowance);
    
    struct Payment {
        address from;
        address to;
        uint256 amount;
        uint256 timestamp;
    }
    
    struct Balance {
        uint256 totalBalance;
        uint256 numPayments;
        mapping(uint256 => Payment) payments;
    }

    
    mapping(address => uint256) public allowances;
    Balance public balance;
    
    modifier onlyOwnerOrAllowed(uint256 _amount) {
        bool isOwner = owner() == msg.sender;
        
        require(isOwner || allowances[msg.sender] >= _amount, "Not allowed");
        _;
    }
    
    function renounceOwnership() public onlyOwner override(Ownable) {
        revert("Cant renounce ownership");
    }
    
    
    function setAllowance(address _dependant, uint256 _allowance) public onlyOwner {
        require(balance.totalBalance >= _allowance, "Not enough funds to allow");
        
        allowances[_dependant] = _allowance;
        
        emit AllowanceChanged(_dependant, _allowance);
    }
}
