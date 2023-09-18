pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import 'hardhat/console.sol';

contract LottyToken is ERC20, ERC20Burnable, AccessControl {
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
  bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');

  constructor(address owner, uint256 initialSupply) ERC20('Lotty', 'LTY') {
    _setupRole(DEFAULT_ADMIN_ROLE, owner);
    _mint(msg.sender, initialSupply);
  }

  function setupRolesForAddress(address _contract) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Caller is not the admin');
    _setupRole(MINTER_ROLE, _contract);
    _setupRole(BURNER_ROLE, _contract);
  }

  function mint(address to, uint256 amount) public {
    // console.log('Does caller has minter role ? : ', hasRole(MINTER_ROLE, msg.sender));
    require(hasRole(MINTER_ROLE, msg.sender), 'Caller is not a minter');
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) public {
    require(hasRole(BURNER_ROLE, msg.sender), 'Caller is not a burner');
    _burn(from, amount);
  }
}
