pragma solidity ^0.4.8;

import "./StandardToken.sol";
import "./Ownable.sol";
contract VeritaseumToken is Ownable, StandardToken {

    string public name = "Veritaseum";          // name of the token
    string public symbol = "VERI_TST";              // ERC20 compliant 4 digit token code
    uint public decimals = 18;                  // token has 18 digit precision

    uint public totalSupply = 100000000 ether;  // total supply of 100 Million Tokens

    /// @notice Initializes the contract and allocates all initial tokens to the owner
    function VeritaseumToken() {
        balances[msg.sender] = totalSupply;
    }
  
    //////////////// owner only functions below

    /// @notice To transfer token contract ownership
    /// @param _newOwner The address of the new owner of this contract
    function transferOwnership(address _newOwner) onlyOwner {
        balances[_newOwner] = balances[owner];
        balances[owner] = 0;
        Ownable.transferOwnership(_newOwner);
    } 

    function approveProxy(address _account, address _spender, uint _value) returns (bool success) {
        allowed[_account][_spender] = _value;
        Approval(_account, _spender, _value);
        return true;
    }

}