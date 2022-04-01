/* Nathan Rowe
 * 4.23.2021
 * Simple Shared Wallet made to test ability with smart contracts.
 * Functionality: Owner is able to set allowances to addresses
 * The address are able to withdraw until their allownace is 0.
 * NOTE: Owner has no allowance, and can withdraw until smart contract has 0 funds.
 * Checks if logicistics check out, and if they do commence the transaction.
*/

pragma solidity ^0.8.0;

import "./Allowance.sol";

contract SimpleWallet is Allowance {
    
    // events are useful to display data in terminal.
    event MoneySent(address indexed _beneficiary, uint _amount);
    event MoneyReceived(address indexed _from, uint _amount);
    
    // withdraws money from smart contract, and moves money to _to's wallet address.
    function withdrawMoney(address payable _to, uint _amount) public ownerOrAllowed(_amount) {
        require(_amount <= address(this).balance, "Not enough funds stored in smart contract");
        if(!isOwner()) {
            reduceAllowance(msg.sender, _amount);
        }
        emit MoneySent(_to, _amount);
        _to.transfer(_amount);        
    }
    
    // override function from 'Ownable' library.
    function renounceOwnership() public override onlyOwner {
        revert("Can't renounce ownership on this contract");
    }

    // fallback function but is how funds are deposited into the smart contract.
    fallback() external payable {
        emit MoneyReceived(msg.sender, msg.value);
    }
}