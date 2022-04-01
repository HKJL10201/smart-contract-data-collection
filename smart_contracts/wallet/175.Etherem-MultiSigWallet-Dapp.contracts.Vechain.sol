pragma solidity 0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VeChain is ERC20 {

    //automatically mint eth on contratc creation
    constructor () ERC20("VeChain", "VET") {

        _mint(msg.sender, 100000000000000000000);
    }

}
