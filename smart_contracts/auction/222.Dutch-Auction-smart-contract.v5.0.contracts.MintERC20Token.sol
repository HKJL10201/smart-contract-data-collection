// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract Gunnercoin is ERC20, ERC20Permit {

    uint256 immutable maxGCNSupply;
    uint256 currenltyUsed;

    constructor(uint256 _maxGCNSupply) ERC20("Gunnercoin", "GCN") ERC20Permit("Gunnercoin") {
        maxGCNSupply = _maxGCNSupply;
    }

    function getMaxGCNSupply() public view returns(uint256){
        return maxGCNSupply;
    }

    function mint(address to, uint256 amount) public {
        require((currenltyUsed + amount) <= maxGCNSupply, "Maximum amount of GCN minting has exceeded");
        _mint(to, amount);
        currenltyUsed += amount;
    }
}
