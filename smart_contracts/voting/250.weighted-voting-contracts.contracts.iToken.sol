pragma solidity ^0.4.19;


interface iToken {
    /// @return total amount of tokens
    function getTotalSupply() public view returns (uint256 supply);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice Get distribution of owners initial tokens
    /// @param _owner The address for which token distribution will be retrieved
    /// @return Array of addresses and array of balances
    function distributionOf(address _owner) public view returns (address[] addresses, uint256[] addressBalances);

    /// @notice Get all members associated with the token
    /// @return Array of addresses and array of balances
    function getMembers() public view returns (address[] addresses);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice Resets tokens for the owner. Returns them to the owners address
    /// @return Whether the transfer was successful or not
    function reset() public returns (bool success);

    /// @notice Add member to the group. Member gets initial tokens
    /// @return True if successfully added
    function addMember() public returns (bool success);

    /// @notice Get name of the group
    /// @return Returns group name
    function getName() public view returns (string name);

    /// @notice Get group symbol
    /// @return Returns group symbol
    function getSymbol() public view returns (string symbol);

    /// @notice Get version of the group
    /// @return Returns group version
    function getVersion() public view returns (string version);

    /// @notice Event propagated on every executed transaction
    event LogTransfer(address indexed _from, address indexed _to, uint256 _value);

    /// @notice Event propagated when new member is added to the group
    event LogAddMember(address indexed _member);
}
