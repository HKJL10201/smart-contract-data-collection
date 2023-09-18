pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract AllowanceWallet is Ownable {
    using SafeMath for uint;

    struct Allowance {
        uint allowanceAmount;
        uint allowancePeriodInDays;
        uint whenLastAllowance;
        uint unspentAllowance;
    }
    
    mapping(address => Allowance) allowances;
    
    event AllowanceCreated(address indexed addr, Allowance newAllowance);
    event AllowanceDeleted(address indexed addr);
    event AllowanceChanged(address indexed addr, Allowance newAllowance);
    event MoneyReceived(address indexed addr, uint amount);
    event MoneySent(address indexed addr, uint amount);

    function addAllowance(address addr, uint allowanceAmount, uint allowancePeriodInDays) public onlyOwner {
        require(allowances[addr].allowanceAmount == 0, "Allowance already exists");
        require(address(this).balance >= allowanceAmount, "Wallet balance too low to add allowance");
        
        // Initialize new allowance
        Allowance memory allowance;
        allowance.allowanceAmount = allowanceAmount;
        allowance.allowancePeriodInDays = allowancePeriodInDays.mul(1 days);
        allowance.whenLastAllowance = block.timestamp;
        allowance.unspentAllowance = allowanceAmount;
        
        allowances[addr] = allowance;
        emit AllowanceCreated(addr, allowance);
    }
    
    function removeAllowance(address payable addr) public onlyOwner {
        require(allowances[addr].allowanceAmount != 0, "Allowance already doesn't exist");
        
        // Payout unspent allowance
        if(allowances[addr].unspentAllowance > 0){
            require(address(this).balance >= allowances[addr].unspentAllowance, "Wallet balance too low to payout unspent allowance");
            addr.transfer(allowances[addr].unspentAllowance);
        }
        
        delete allowances[addr];
        
        emit MoneySent(addr, allowances[addr].unspentAllowance);
        emit AllowanceDeleted(addr);
    }
    
    function getPaidAllowance(uint amount) public {
        require(allowances[msg.sender].allowanceAmount > 0, "You're not a recipient of an allowance");
        require(address(this).balance >= amount, "Wallet balance too low to pay allowance");
        
        // Calculate and update unspent allowance
        uint numAllowances = block.timestamp.sub(allowances[msg.sender].whenLastAllowance).div(allowances[msg.sender].allowancePeriodInDays);
        allowances[msg.sender].unspentAllowance = allowances[msg.sender].allowanceAmount.mul(numAllowances).add(allowances[msg.sender].unspentAllowance);
        allowances[msg.sender].whenLastAllowance = numAllowances.mul(1 days).add(allowances[msg.sender].whenLastAllowance);
        
        // Pay allowance
        require(allowances[msg.sender].unspentAllowance >= amount, "You asked for more allowance than you're owed'");
        payable(msg.sender).transfer(amount);
        allowances[msg.sender].unspentAllowance = allowances[msg.sender].unspentAllowance.sub(amount);
        
        emit MoneySent(msg.sender, amount);
        emit AllowanceChanged(msg.sender, allowances[msg.sender]);
    }
    
    function withdrawFromWalletBalance(address payable addr, uint amount) public onlyOwner {
        require(address(this).balance >= amount, "Wallet balance too low to fund withdraw");
        addr.transfer(amount);
        
        emit MoneySent(msg.sender, amount);
    }
    
    function withdrawAllFromWalletBalance(address payable addr) public onlyOwner {
        withdrawFromWalletBalance(addr, address(this).balance);
    }
    
    function renounceOwnership() public override view onlyOwner {
        revert("Can't renounce ownership");
    }
    
    receive () external payable {
        emit MoneyReceived(msg.sender, msg.value);
    }
}
