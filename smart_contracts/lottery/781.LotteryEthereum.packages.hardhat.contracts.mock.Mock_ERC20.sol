//SPDX-License-Identifier: MIT
pragma solidity >0.8.0 <=0.9.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

/**
 * @dev THIS CONTRACT IS FOR TESTING PURPOSES ONLY.
 */
contract Mock_ERC20 is ERC20 {
  constructor(uint256 _supply) ERC20('Link', '$LINK') {
    _mint(msg.sender, _supply);
  }

  function mint(address _to, uint256 _amount) public {
    _mint(_to, _amount);
  }

  /**
   * @dev This function is only here to accommodate nested Link token
   *      functionality required in mocking the random number calls.
   */
  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success) {
    return true;
  }
}
