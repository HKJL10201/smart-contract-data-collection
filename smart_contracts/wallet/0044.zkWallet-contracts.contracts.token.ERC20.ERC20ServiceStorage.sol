// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title ERC20Service Storage base on Diamond Standard Layout storage pattern
 */
library ERC20ServiceStorage {
    struct Layout {
        mapping(address => uint256) erc20TokenIndex;
        address[] erc20Tokens;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.ERC20Service");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice add an ERC20 token to the storage
     * @param tokenAddress: the address of the ERC20 token
     */
    function storeERC20(Layout storage s, address tokenAddress)
        internal {
            uint256 arrayIndex = s.erc20Tokens.length;
            uint256 index = arrayIndex + 1;
            s.erc20Tokens.push(tokenAddress);
            s.erc20TokenIndex[tokenAddress] = index;
    }

    /**
     * @notice delete an ERC20 token from the storage,
     * we are going to switch the last item in the array with the one we are replacing.
     * That way when we pop, we are removing the correct item. 
     *
     * There are two cases we need to handle:
     *  - the address we are removing is not the last address in the array
     *  - or it is the last address in the array. 
     * @param tokenAddress: the address of the ERC20 token
     */
    function deleteERC20(Layout storage s, address tokenAddress)
        internal {
            uint256 index = s.erc20TokenIndex[tokenAddress];
            uint256 arrayIndex = index - 1;
            require(arrayIndex >= 0, "ERC20_NOT_EXISTS");
            if(arrayIndex != s.erc20Tokens.length - 1) {
                 s.erc20Tokens[arrayIndex] = s.erc20Tokens[s.erc20Tokens.length - 1];
                 s.erc20TokenIndex[s.erc20Tokens[arrayIndex]] = index;
            }
            s.erc20Tokens.pop();
            delete s.erc20TokenIndex[tokenAddress];
    }
}
