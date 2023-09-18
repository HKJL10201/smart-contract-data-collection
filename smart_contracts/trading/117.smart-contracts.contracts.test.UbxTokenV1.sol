// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../UbxToken.sol";
import "../utils/math/SafeMath.sol";

/**
 * @title Token_V1
 * @dev Version 1 of a token to show upgradeability.
 * The idea here is to extend a token behaviour providing burnable functionalities
 * in addition to what's provided in version 0
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to aother accounts
 */
contract UbxTokenV1 is UbxToken {
    using SafeMath for uint256;
    //uint256 private _totalSupply;
    //uint256 public _totalSupplytruc;
    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    event InitV2(uint256 value);
    event BurnDouble(address indexed burner, uint256 value);

    function init2(uint256 newSupply) public {
        emit InitV2(newSupply);
        TokenStorage storage ercs = erc20Storage();
        ercs.totalSupply = newSupply;
    }

    function mint(address account, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        _mint(account, amount);
        return true;
    }

    function depositEther() external payable {
        //do something inside..
    }

    function burnDouble(uint256 value) public {
        require(
            balanceOf(msg.sender) >= value.mul(2),
            "balance too low to burn"
        );
        TokenStorage storage ercs = erc20Storage();
        ercs.balances[msg.sender] = ercs.balances[msg.sender].sub(value.mul(2));
        ercs.totalSupply = ercs.totalSupply.sub(value.mul(2));
        emit BurnDouble(msg.sender, value.mul(2));
    }
}
