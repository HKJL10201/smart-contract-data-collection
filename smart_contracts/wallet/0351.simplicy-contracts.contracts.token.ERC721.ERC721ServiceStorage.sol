// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title ERC721Service Storage base on Diamond Standard Layout storage pattern
 */
library ERC721ServiceStorage {
    enum Error {
        None,
        RevertWithMessage,
        RevertWithoutMessage,
        Panic
    }

    struct Layout {
        mapping(address => uint256) erc721TokenIndex;
        address[] erc721Tokens;
        bytes4 retval;
        Error error;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.ERC721Service");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice add an ERC721 token to the storage
     * @param tokenAddress: the address of the ERC721 token
     */
    function storeERC721(Layout storage s, address tokenAddress)
        internal {
            uint256 arrayIndex = s.erc721Tokens.length;
            uint256 index = arrayIndex + 1;
            s.erc721Tokens.push(tokenAddress);
            s.erc721TokenIndex[tokenAddress] = index;
    }

    /**
     * @notice delete an ERC721 token from the storage,
     * we are going to switch the last item in the array with the one we are replacing.
     * That way when we pop, we are removing the correct item. 
     *
     * There are two cases we need to handle:
     *  - the address we are removing is not the last address in the array
     *  - or it is the last address in the array. 
     * @param tokenAddress: the address of the ERC20 token
     */
    function deleteERC721(Layout storage s, address tokenAddress)
        internal {
            uint256 index = s.erc721TokenIndex[tokenAddress];
            uint256 arrayIndex = index - 1;
            require(arrayIndex >= 0, "ERC721_NOT_EXISTS");
            if(arrayIndex != s.erc721Tokens.length - 1) {
                 s.erc721Tokens[arrayIndex] = s.erc721Tokens[s.erc721Tokens.length - 1];
                 s.erc721TokenIndex[s.erc721Tokens[arrayIndex]] = index;
            }
            s.erc721Tokens.pop();
            delete s.erc721TokenIndex[tokenAddress];
    }
}
