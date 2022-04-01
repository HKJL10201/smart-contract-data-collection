pragma solidity ^0.6.0;
import "./allowance.sol";

contract SmartWallet is Allowance{
    
    event MoneySent(address indexed _beneficiary, uint amount);
    event MoneyReceived(address indexed _from, uint _amount);
    
    // function to withdraw money from SmartWallet
    function withdrawMoney(address payable _to, uint256 _amount) public allowancePermissions(_amount) {
        // reduce the amount of the allowance variable to prevent double spending. ! indicatates "not"
        require(_amount <= address(this).balance, "Not enough funds in contract.");
        if(!isOwner()) {
            reduceAllowance(msg.sender, _amount);
        }
        // emit the event here so when money is withdrawn we can see who it was sent to
        emit MoneySent(_to, _amount);
        _to.transfer(_amount);
    }
    
    // create a function to override renounceOwnership function inherited from Ownable library
    function renounceOwnership() public override onlyOwner {
        revert("Renouncing ownership not permitted.");
    }
    
    // fallback funtion to allow deposits to the smart contract
    receive() external payable {
        // emit here to see who sent money to the contact and how much
        emit MoneyReceived(msg.sender, msg.value);
    }
    
}