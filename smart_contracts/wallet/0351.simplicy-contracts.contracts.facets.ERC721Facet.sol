// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import {IERC721Receiver} from "@solidstate/contracts/token/ERC721/IERC721Receiver.sol";
import {ERC721Service} from "../token/ERC721/ERC721Service.sol";
import {ERC721ServiceStorage} from "../token/ERC721/ERC721ServiceStorage.sol";

contract ERC721Facet is ERC721Service, IERC721Receiver, OwnableInternal {
    using ERC721ServiceStorage for ERC721ServiceStorage.Layout;
    using ERC721ServiceStorage for ERC721ServiceStorage.Error;

    event Received(address operator, address from, uint256 tokenId, bytes data, uint256 gas);

    /**
     * @notice return the current version of ERC721Facet
     */
    function erc721FacetVersion() public pure returns (string memory) {
        return "0.0.1";
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override returns (bytes4) {
        if (ERC721ServiceStorage.layout().error == ERC721ServiceStorage.Error.RevertWithMessage) {
            revert("ERC721Facet: reverting");
        } else if (ERC721ServiceStorage.layout().error == ERC721ServiceStorage.Error.RevertWithoutMessage) {
            revert();
        } else if (ERC721ServiceStorage.layout().error == ERC721ServiceStorage.Error.Panic) {
            uint256 a = uint256(0) / uint256(0);
            a;
        }
        emit Received(operator, from, tokenId, data, gasleft());
        return ERC721ServiceStorage.layout().retval;
    }

    function _beforeTransferERC721(address token, address to, uint256 tokenId) internal virtual view override onlyOwner {
        super._beforeTransferERC721(token, to, tokenId);
    }

    function _beforeApproveERC721(address token, address spender, uint256 tokenId) internal virtual view override onlyOwner {
        super._beforeApproveERC721(token, spender, tokenId);
    }

    function _beforeRegisterERC721(address tokenAddress) internal virtual view override onlyOwner {
        super._beforeRegisterERC721(tokenAddress);
    }

    function _beforeRemoveERC721(address tokenAddress) internal virtual view override onlyOwner {
        super._beforeRemoveERC721(tokenAddress);
    }
}