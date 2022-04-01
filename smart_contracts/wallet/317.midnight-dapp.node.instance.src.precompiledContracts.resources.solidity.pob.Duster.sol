pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
import "../Constants.sol";
import "./IERC20.sol";
import "./IDuster.sol";

/// @title  Base contract to be used to represent all ERC20 PoB tokens
/// @notice All the duster calls can emit money if successful, no function that shouldn't do that should be added
contract Duster is IDuster {

    modifier onlyFromClaimer() {
        require(msg.sender == Constants.claimer(), "Only Claimer can mint ERC20 tokens");
        _;
    }

    // It's not allowed to send money to the Duster
    receive () external payable {
        assert(false);
    }

    /// @notice This method receives certain amount of tokens to be changed to Dust
    /// @param chainId Id of the chain from which the tokens belong
    /// @param tokens Amount of ERC20 tokens to destroy
    /// @return burned Amount of Dust to issue
    /// @return recipient The receiver of the transparent dust
    /// @dev This function is likely to change in order to include a way to be able to query another contract
    /// to determine the rate and the allowed amount to exchange
    function toDust(uint8 chainId, uint tokens) override public returns (uint burned, address recipient) {
        return _toDust(chainId, msg.sender, tokens);
    }

    /// @dev This function can only be called from Claimer contract as the from is specified instead of using msg.sender
    function toDustFrom(uint8 chainId, address from, uint256 tokens) override public onlyFromClaimer() returns (uint burned, address recipient){
        return _toDust(chainId, from, tokens);
    }

    function _toDust(uint8 chainId, address from, uint256 tokens) internal returns (uint burned, address recipient) {
        IERC20 erc20 = IERC20(address(uint160(Constants.erc20TokenStart()) + chainId));
        erc20.burn(from, tokens);
        return (tokens, from);
    }
}
