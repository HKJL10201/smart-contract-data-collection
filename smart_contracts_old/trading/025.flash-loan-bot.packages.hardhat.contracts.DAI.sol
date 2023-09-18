pragma solidity >=0.6.0 <0.7.0;

import { IERC20 } from "./Interfaces.sol";
import { Constants } from "./Constants.sol";

import "hardhat/console.sol";

contract DAI {
  IERC20 public dai;
  address private DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

  constructor() public {
    dai = IERC20(DAI_ADDRESS);
  }

  function getMyDAIBalance(address check) public view returns (uint256) {
    return dai.balanceOf(check);
  }
}
