pragma solidity 0.6.2;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "./ERC20.sol";

contract CaseToken is ERC20, Initializable {
    function initialize(address admin) public initializer {
        _initialize("Case Token", "CASE", 8);
        
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MINTER_ROLE, admin);
    }

    function mint(address recipient, uint256 amount) public returns (bool) {
        require(hasRole(MINTER_ROLE, _msgSender()), "mint: unauthorized call!");

        _mint(recipient, amount);

        return true;
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }
}
