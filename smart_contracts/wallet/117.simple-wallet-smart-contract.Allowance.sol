// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Allownace is Ownable {
    
    event AllownaceChanged(address indexed _forWho, address _fromWhom, uint _oldAmount, uint _newAmount);
    
    mapping(address => uint) public allowance;
    
    function addAllownace(address _who, uint _amount) public onlyOwner{
        // here the msg.sender is the owner who deployed the smart contract
        emit AllownaceChanged(_who, msg.sender, allowance[_who], _amount);
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
        emit AllownaceChanged(_who, _to, allowance[_who], allowance[_who] - _amount);
        allowance[_who] -= _amount;
    }
}