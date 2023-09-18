// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract ERC2981Royalties is ERC165 {
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }
    mapping(uint256 => RoyaltyInfo) private _royalties;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _setTokenRoyalty(
        uint256 _tokenId,
        address _recipient,
        uint256 _value
    ) internal {
        require(_value <= 10000, "ERC2981Royalties: Too high");
        _royalties[_tokenId] = RoyaltyInfo(_recipient, uint24(_value));
    }

    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties[tokenId];
        receiver = royalties.recipient;
        royaltyAmount = (value * royalties.amount) / 10000;
    }
}
