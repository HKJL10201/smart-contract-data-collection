pragma solidity ^0.4.24;

contract RevertContract {

    /// @dev Fallback function.
    function () external payable {
        revert("HonestContract");
    }
}