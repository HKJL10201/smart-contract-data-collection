pragma solidity ^0.4.19;


interface iPoll {
    /// @notice Vote on the poll
    function vote() public returns (bool success);

    /// @notice Finish poll
    function closePoll() public returns (bool success);
}
