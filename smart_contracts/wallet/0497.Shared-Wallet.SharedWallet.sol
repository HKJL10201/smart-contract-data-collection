pragma solidity ^0.8.4;

import "./Allowance.sol";

contract SharedWallet is Allowance {
    
    event moneySent(address indexed _toWhom, uint _amount);
    event moneyReceived(address indexed _fromWho, uint _amount);
    
    function renounceOwnership() public view override onlyOwner {
        revert("Can not renounceOwnership here!");
    }
    
    function seeContractBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function withdrawMoney(address payable _to, uint _amount) public OwnerOrAllowed(_amount) {
        require(_amount <= address(this).balance, "Contract does not have enough funds.");
        emit moneySent(_to, _amount);
        if (!isOwner()){
            reduceAllowance(_to, _amount);
        }
        
        _to.transfer(_amount);
    }
    
    function receiveMoney() internal {
        emit moneyReceived(msg.sender, msg.value);
        if (!isOwner()){
            receivePayment(msg.sender,msg.value);
        }
    }
    
    receive() external payable {
        receiveMoney();
    }
    
}
