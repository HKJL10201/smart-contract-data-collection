//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract OwnableExtended is Ownable {
    function isOwner() public view virtual returns (bool) {
        return msg.sender == owner();
    }
}

contract Allowance is OwnableExtended {

    using SafeMath for uint;

    mapping(address => uint) public allowance;

    event AllowanceChanged(address indexed _from, address indexed _to, uint _oldAmount, uint _updatedAmount);

    modifier isOwnerOrAllowed(uint _amount) {
        // || allowance[msg.sender] > _amount, "You are not allowed!"
        require(isOwner() || allowance[msg.sender] >= _amount, "You are not Allowed!");
        _;
    }

    function addAllowance(address _recipient, uint _amount) public onlyOwner {
        emit AllowanceChanged(msg.sender, _recipient, allowance[_recipient], _amount );
        allowance[_recipient] = _amount;
    }

    function reduceAllowance(address _recipient, uint _amount) internal {
         emit AllowanceChanged(msg.sender, _recipient, allowance[_recipient], allowance[_recipient].sub(_amount) );
        allowance[_recipient] = allowance[_recipient].sub(_amount);
    }
}

contract SharedWallet is Allowance {

    event MoneySent(address _to, uint _value);
    event Received(address _from, uint _value);

    function renounceOwnership() public virtual override onlyOwner{
        revert("Cannot renounce ownership");
    }

    function withdrawMoney(address payable _recipient, uint _amount) public isOwnerOrAllowed(_amount){
        require(address(this).balance >= _amount, "Not enough funds!");
        reduceAllowance(_recipient, _amount);
        _recipient.transfer(_amount);
        emit MoneySent(_recipient, _amount);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

}