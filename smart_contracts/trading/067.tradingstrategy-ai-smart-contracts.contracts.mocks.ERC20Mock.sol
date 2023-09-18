

import "@openzeppelin/contracts-v4/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {

    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol) public {
        _decimals = decimals;
    }

    function mint(address account, uint256 amount) public returns (bool) {
        _mint(account, amount);
        return true;
    }
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
