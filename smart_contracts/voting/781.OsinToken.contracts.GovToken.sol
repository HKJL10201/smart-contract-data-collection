// contracts/GovToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OSIVoting.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GovToken is ERC20 {

    OSIVoting public voting;

    constructor(address _origin, uint256 _supply) ERC20("OSI Goverance", "OSI_GOV") {
        _mint(_origin, _supply);
        voting = OSIVoting(msg.sender);
    }

    function _afterTokenTransfer(address _from, address _to, uint256 _amount) internal virtual override {
        // avoids during initial minting
        if (_from != address(0))
            voting.goveranceTransfer(msg.sender, _to, _amount);
    } 

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
}
