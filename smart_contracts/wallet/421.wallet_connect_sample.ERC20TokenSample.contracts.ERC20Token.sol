// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

contract ERC20Token is ERC20, AccessControl {
    // Create a new role identifier for the minter role

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Create a new role identifier for the burner role

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(
        string memory _name,
        string memory _symbol,
        address _minter,
        address _burner
    ) ERC20(_name, _symbol) {
        // Grant the contract deployer the default admin role: it will be able to grant and revoke any roles

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Grant the minter role to a specified account

        _grantRole(MINTER_ROLE, _minter);

        // Grant the burner role to a specified account

        _grantRole(BURNER_ROLE, _burner);
    }

    function mint(uint256 _amount) public onlyRole(MINTER_ROLE) {
        //ERC20 Tokens have 18 decimals, total number of tokens minted for given amount,total=amount * 10^18

        _mint(msg.sender, _amount * 10**uint256(decimals()));
    }

    function burn(address _account, uint256 _amount)
        public
        onlyRole(BURNER_ROLE)
    {
        _burn(_account, _amount * 10**uint256(decimals()));
    }
}
