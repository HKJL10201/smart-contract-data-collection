// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./abstract/ERC1155Factory.sol";

contract ApesTraits is ERC1155Factory {
    using Strings for uint256;

    mapping(uint256 => uint256) public traitLimit;
    mapping(address => bool) public isMinter;

    event Minted(uint256 tokenId, uint256 amount, address to, address operator);
    event MintedBatch(
        uint256[] ids,
        uint256[] amounts,
        address to,
        address operator
    );

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri) {
        name_ = _name;
        symbol_ = _symbol;
    }

    modifier onlyMinter() {
        require(isMinter[msg.sender], "Mint: Not authorized to mint");
        _;
    }

    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external onlyMinter {
        if (traitLimit[tokenId] > 0) {
            require(
                amount + totalSupply(tokenId) <= traitLimit[tokenId],
                "Mint: Exceed trait limit"
            );
        }

        _mint(to, tokenId, amount, "");

        emit Minted(tokenId, amount, to, msg.sender);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyMinter {
        _mintBatch(to, ids, amounts, "");

        emit MintedBatch(ids, amounts, to, msg.sender);
    }

    function setTraitLimit(uint256 tokenId, uint256 limit) external onlyOwner {
        traitLimit[tokenId] = limit;
    }

    function bulkSetTraitLimit(
        uint256[] calldata tokenIds,
        uint256[] calldata limits
    ) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            traitLimit[tokenIds[i]] = limits[i];
        }
    }

    function setIsMinter(address operator, bool status) external onlyOwner {
        isMinter[operator] = status;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");

        return string(abi.encodePacked(super.uri(_id), _id.toString()));
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        for (uint256 i = 0; i < ids.length; i++) {
            if (traitLimit[ids[i]] > 0) {
                require(
                    amounts[i] + totalSupply(ids[i]) <= traitLimit[ids[i]],
                    "Mint: Exceed trait limit"
                );
            }
        }

        super._mintBatch(to, ids, amounts, data);
    }
}
