// Abstract contract for the ERC 179 Token standard draft, equivalent to ERC 20 without allowance mechanism.
pragma solidity ^0.4.18;

contract ERC179Interface {
    /// @return The total token supply
    function totalSupply() public view returns (uint256);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
}