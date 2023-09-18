pragma solidity >=0.6.0 <0.8.0;

import '../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract Link is ERC20 {
//We make a constructor which will call the ERC20 constructor, 
//with Chainlink as the name and LINK as the ticker.
//And we will mint 1000 tokens to ourselves, to msg.sender, for testing.
//This token has the functions we need for testing, like transfer and transferFrom.
    constructor() ERC20("Chainlink", "LINK") public {
        _mint(msg.sender, 1000);
    }
}
