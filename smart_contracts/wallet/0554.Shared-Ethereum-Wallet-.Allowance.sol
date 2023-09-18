pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.4.0/contracts/ownership/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.4.0/contracts/math/SafeMath.sol";

contract Allowance is Ownable {
    
    using SafeMath for uint;

    event AllowanceChanged(address indexed _forWho , address indexed _fromWhom , uint _oldAmount , uint _newAmount);

    mapping(address=>uint) public allownance;

    function addAllowance (address _who , uint _amount ) public onlyOwner {
        emit AllowanceChanged(_who,msg.sender,allownance[_who],_amount);
        allownance[_who] = _amount;
    } 

    modifier ownerOrAllowed(uint _amount) {
        require(isOwner() || allownance[msg.sender] >= _amount, "You are not allowed");
        _;
    }

    function reduceAllowance(address _who , uint _amount ) internal {
        emit AllowanceChanged(_who,msg.sender,allownance[_who], allownance[_who] - _amount);
        allownance[_who] = allownance[_who].sub(_amount);
    }
}
