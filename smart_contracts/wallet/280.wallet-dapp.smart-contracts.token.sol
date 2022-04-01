pragma solidity ^0.6.0;
import "./contracts/token/ERC20/ERC20.sol";

contract ETHC is ERC20 {
    constructor() ERC20("Ethcode", "ETHC") public {
        _mint(msg.sender, 100);
    }
}