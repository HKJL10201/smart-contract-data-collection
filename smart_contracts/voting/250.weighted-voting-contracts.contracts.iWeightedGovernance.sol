pragma solidity ^0.4.19;


interface iWeightedGovernance {

    /// @notice Create new Group
    /// @param _name Set group name
    /// @param _symbol Set group symbol
    /// @param _initialAmount Set members initial token amount
    /// @param _decimalUnits Set decimal units for the token
    /// @return Returns address of the created group
    function createGroup(string _name, string _symbol, uint256 _initialAmount, uint8 _decimalUnits) public returns (address group);

    /// @notice Create new Poll
    /// @return Returns address of the created poll
    function createPoll() public returns (address poll);

    /// @notice Get created groups
    function getGroups() public view returns (address[] existingGroups);

    /// @notice Get created polls
    function getPolls() public view returns (address[] existingPolls);
}
