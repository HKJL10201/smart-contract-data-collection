// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./interfaces/IBlockAddresses.sol";
import "./helpers/zeroAddressPreventer.sol";

/**
 * @title BLOCK NFT.
 * @author javad_yakuza.
 * @notice @dev this is NFT Token with ERC-115 standard to represent the houses in BlockRoom
 */
contract Block is ERC1155, Ownable, ERC1155Supply, ZAP {
    /// @dev emmited ehen a new Block is minted by the `mintBlock` function
    event NewBlock(
        address indexed Blocker,
        uint256 _Blokcer,
        uint256 _component
    );

    constructor(
        IBlockAddresses tempIBlockAddresses
    ) ERC1155("") nonZeroAddress(address(tempIBlockAddresses)) {
        BlockAddresses = tempIBlockAddresses;
    }

    IBlockAddresses public immutable BlockAddresses;

    modifier onlyOwnerOrBlockWrapper() {
        require(
            msg.sender == owner() ||
                BlockAddresses.modifierIsBlockWrapper(msg.sender),
            "not the owner or BlockWrapper !!"
        );
        _;
    }

    function mintBlock(
        address _account,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external onlyOwnerOrBlockWrapper {
        require(_amount + totalSupply(_id) <= 6, "component overflow !!");
        require(_id != 0, "blockId can not be zero !!");
        _mint(_account, _id, _amount, _data);
        emit NewBlock(_account, _id, _amount);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override nonZeroAddress(operator) {
        _setApprovalForAll(_msgSender(), operator, approved);
    }
}
