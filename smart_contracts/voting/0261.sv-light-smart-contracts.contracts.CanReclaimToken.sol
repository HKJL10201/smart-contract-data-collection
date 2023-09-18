pragma solidity ^0.4.23;

import { owned, ERC20Interface } from "./SVCommon.sol";

// modified version of CanReclaimToken
// from: https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/token/ERC20/SafeERC20.sol
// license: MIT


/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is owned {

    /**
    * @dev Reclaim all ERC20Basic compatible tokens
    * @param token ERC20Basic The address of the token contract
    */
    function reclaimToken(ERC20Interface token) external only_owner {
        uint256 balance = token.balanceOf(this);
        require(token.approve(owner, balance));
    }

}
