// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract HelloWorld {
  string public messageState = "Ola semana solidity!";

  string public constant MESSAGE_CONSTANT = "Ola constante!";

  address public constant DONATION_ADDRESS = 0x0000000000000000000000000000000000000000;

  address public immutable OWNER;

  constructor () {
    OWNER = msg.sender;
  }

  function greetings() public pure returns (string memory) {
    string memory internalMessage = "Ola semana solidity!";
    return internalMessage;
  }

  function getBlockNumber() public view returns (uint256) {
    return block.number;
  }
}