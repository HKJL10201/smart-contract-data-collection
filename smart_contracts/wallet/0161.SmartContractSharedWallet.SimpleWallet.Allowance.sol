/* Nathan Rowe
 * 4.23.2021
 * Allowance contract for each address in the shared simple wallet.
*/

pragma solidity ^0.8.0;

// imported conracts from github.. useful for ownership and safemath.
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

contract Allowance is Ownable {
    
    using SafeMath for uint;
    
    // events
    event AllowanceChanged(address indexed _forWho, address indexed _fromWhom, uint _oldAmt, uint _newAmt);
    
    // mapping data structure is essentially a dictionary with address : allowance.
    mapping(address => uint) public allowance;
    
    // sets addresses' allowance only done by the owner of the contract aka Shared Wallet.
    function setAllowance(address _who, uint _amount) public onlyOwner {
        emit AllowanceChanged(_who, msg.sender, allowance[_who], _amount);
        allowance[_who] = _amount;
    }
    
    function reduceAllowance(address _who, uint _amount) internal {
        emit AllowanceChanged(_who, msg.sender, allowance[_who], allowance[_who].sub(_amount));
        allowance[_who] = allowance[_who].sub(_amount);
    }
    
    modifier ownerOrAllowed(uint _amount) {
        require(isOwner() || allowance[msg.sender] > _amount, "You are not allowed");
        _;
    }
    
}