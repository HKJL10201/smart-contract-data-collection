// contracts/RewToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OSIVoting.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewToken is ERC20, Ownable {

    OSIVoting public voting;


    constructor() ERC20("OSI Rewards", "OSI") {
        voting = OSIVoting(msg.sender);
    }

    function _afterTokenTransfer(address, address _to, uint256 _amount) internal virtual override {
        voting.rewardsTransfer(msg.sender, _to, _amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 3;
    }
}
