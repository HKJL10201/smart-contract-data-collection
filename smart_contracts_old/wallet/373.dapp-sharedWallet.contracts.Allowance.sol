pragma solidity 0.8.4;

import './Ownable.sol';

contract Allowance is Ownable {
    mapping(address => uint) public allowance;
    
      function reduceAllowance(uint amount) internal {
        allowance[msg.sender] -= amount;
    }
    
    function changeAllowance(address recipient, uint amount) public onlyOwner {
        allowance[recipient] = amount;
    }
    
    modifier onlyOwnerOrAllowed(uint amount) {
        require(isOwner() || amount <= allowance[msg.sender], 'You want to withdraw more than you are allowed to');
        _;
    }
    
}