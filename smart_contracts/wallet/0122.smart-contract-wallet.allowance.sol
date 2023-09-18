pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/math/SafeMath.sol";


// For strutural purposes and auditaility break up contracts into their specific use cases.
// In this case a contract for the allowance functionality and one for withdraw/deposits
contract Allowance is Ownable {
    
    // using safemath library
    using SafeMath for uint;
    
    // adding events allows a user to know what's happening in the contract
    // indexing the addresses makes it easier to search for them in the event chain (in the logs)
    event AllowanceChanged(address indexed _forWho, address indexed _fromWho, uint256 oldAmount, uint256 newAmount);
    
     mapping(address => uint256) public allowance;
    
    // function to add an allowance to the smart contract. Give only the onwer permissions to do so, who can wihdraw and how much
    function addAllowance(address _who, uint256 _amount) public onlyOwner{
        // events have to be emitted
        emit AllowanceChanged(_who, msg.sender, allowance[_who], _amount);
        allowance[_who] = _amount;
    }
    
    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }
    
    // create a modifier to extend withdraw functionality
    // either the owner or the person allowed to withdraw the allowance can do so.
    // || is an or statement
    modifier allowancePermissions(uint256 _amount) {
        require(isOwner() || allowance[msg.sender] >= _amount, "Withdraw denied. Withdraw requires ownership or withdraw permissions");
        _;
    }
    
    // function to reduce amount of allowance to prevent double spending
    // sub function from safemath library
    function reduceAllowance(address _who, uint256 _amount) internal allowancePermissions(_amount) {
        emit AllowanceChanged(_who, msg.sender, allowance[_who], allowance[_who].sub(_amount));
        allowance[_who] = allowance[_who].sub(_amount);
    }
}