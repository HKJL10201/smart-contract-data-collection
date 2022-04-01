// TO DO 1 Contract Allowance
pragma solidity ^0.6.10;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/ConsenSysMesh/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol";


// TO DO 1.1: Create a contract 'Allowance' which has an inheritance contract 'Ownable' in OpenZeppelin
contract Allowance is Ownable{    
    // Use 'SafeMath' in 'OpenZeppelin' for uint
    using SafeMath for uint;
    
    // An event for changing the allowance
    event AllowanceChanged(address indexed _forWho, address indexed _byWhom, uint _oldAmount , uint _newAmount);
    
    // TO DO 1.2: Create a public mapping 'allowance' which has key type address to value type uint
    mapping(address => uint) public allowance;
    
    // A return function which decides if msg.send is the owner
    function isOwner() internal view returns(bool) {
        return msg.sender == owner();
    }
    
    // Only allows owner to change the allowance
    function setAllowance(address _who, uint _amount) public onlyOwner { 
        emit AllowanceChanged(_who, msg.sender, allowance[_who], _amount); 
        allowance[_who] = _amount;
    }
    
    // A modifier function that check the condition
    modifier ownerOrAllowed(uint _amount) {

        // TO DO 1.3: Create a require function that msg.sender isOwner or the allowance of msg.sender is bigger than '_amount', the error message is "You are not allowed!"
        require(isOwner() || allowance[msg.sender] > _amount, "You are not allowed");
        _;
    }
    
    // Reduce allowance of the selected address
    function reduceAllowance(address _who, uint _amount) internal ownerOrAllowed(_amount) {
        emit AllowanceChanged(_who, msg.sender, allowance[_who], allowance[_who].sub(_amount));
        allowance[_who] = allowance[_who].sub(_amount);
    }
}
