// TO DO 2 Contract SharedWallet
pragma solidity ^0.6.10;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/ConsenSysMesh/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol";

// TO DO 2.1: Import 'Allowance.sol'
import "./Allowance.sol";

// TO DO 2.2: Create a contract 'SharedWallet' which has two inheritance contracts: 'Ownable' and 'Allowance'
contract SharedWallet is Ownable, Allowance{
    // An event for sending money
    event MoneySent(address indexed _beneficiary, uint _amount); 
    
    // TO DO 2.3: Create an event 'MoneyReceived' which has _from and _to
    event MoneyReceived(address _from, address _to);
    
    // Withdraw money
    function withdrawMoney(address payable _to, uint _amount) public ownerOrAllowed(_amount) {
        require(_amount <= address(this).balance, "Contract doesn't own enough money"); 
        
        if(!isOwner()) {
            reduceAllowance(msg.sender, _amount); 
        }
        
        // TO DO 2.4: Emit event 'MoneySent'
        emit MoneySent(_to, _amount);
        
        // TO DO 2.5: Transfer '_amount' to address '_to'
        _to.transfer(_amount);
    }

    // Revert the function 'renounceOwnership'
    function renounceOwnership() public override onlyOwner {
        
        // TO DO 2.6: Create a revert function with message "can't renounceOwnership here"
        revert("can't renounceOwnership here");
    }
    
    // TO DO 2.7: Create a receive ether function 
    receive() external payable {   
        // TO DO 2.8: Emit event 'MoneyReceived'
        emit MoneyReceived(address(this), msg.sender);
        // The code below works!
        // emit MoneyReceived(msg.sender, msg.sender);
    } 
}
