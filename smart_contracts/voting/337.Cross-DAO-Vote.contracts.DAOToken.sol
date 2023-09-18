//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "./ERC1155PermitUpgradeable.sol";
import "hardhat/console.sol";

contract DAOToken is IERC165Upgradeable, ERC1155PermitUpgradeable {

    /**
    * @dev Initialize function are only called once for upgradeable proxy contract
           This contract does not use constructor function to avoid state variables conflicts
           Initiates EIP-712 'name' for EIP-2612 Permit usage
    */
    function initialize() initializer public payable {
        __ERC1155_init("https://ipfs.io/ipfs/abcdefg/{id}.json");
        __ERC1155Permit_init("DAOToken");
    }

    /**
    * @dev ERC1155 mint function
    */
    function mint(address _to,
                uint256 _id,
                uint256 _amount,
                bytes memory _data)
    external {
        _mint(_to, _id, _amount, _data);
    }

    /**
    * @dev This contract implement EIP-2612 which uses Permit function that
           verify signature for token handling approval.
           See {IERC165-supportsInterface}.
    */
    function supportsInterface(bytes4 interfaceId) public view virtual 
    override(IERC165Upgradeable, ERC1155Upgradeable) 
    returns (bool) {
        return
        interfaceId == type(IERC1155Upgradeable).interfaceId ||
        interfaceId == bytes4(keccak256("permit(address,address,uint256,uint8,bytes32,bytes32")) ||
        super.supportsInterface(interfaceId);
    }
}