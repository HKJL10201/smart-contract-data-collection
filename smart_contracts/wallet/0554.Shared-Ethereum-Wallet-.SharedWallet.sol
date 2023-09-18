pragma solidity ^0.5.0;
import "./Allowance.sol";

contract SharedWallet is Allowance { 

    event MoneySent(address indexed _theLuckGetter , uint _amount);
    event MoneyReceived(address indexed _from , uint _amount); 


    function withDrawMoney(address payable _addressToSendMoney , uint _amount) public ownerOrAllowed(_amount) {
        require(_amount <= address(this).balance , "There is not enough funds stored in the smart contract");
        if (!isOwner()) {
            reduceAllowance(msg.sender , _amount);
        }
        emit MoneySent(_addressToSendMoney,_amount);
        _addressToSendMoney.transfer(_amount);
    }

    function renounceOwnership() public onlyOwner {
        revert("Can't renounce ownership here !");
    }
    
    function () external payable {
        emit MoneyReceived(msg.sender , msg.value);
    } 
}
