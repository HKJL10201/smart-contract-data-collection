// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                );
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

contract MyNFT is ERC721, ERC721URIStorage, AccessControl, Ownable, IERC165, IERC2981, ContextMixin, ERC2771Context {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes4 private constant _INTERFACE_ID_ERC2981 = type(IERC2981).interfaceId;

    event Mint(address indexed to, uint256 tokenId, string uri);
    event MinterRoleGranted(address indexed minter, uint256 minTokenId, uint256 maxTokenId);
    event MinterRoleRevoked(address indexed minter);
    event RoyaltyRecipientChanged(address indexed newRoyaltyRecipient);

    string private _contractURI;
    mapping (address => bool) private _whitelist;

    //Note for constructor: as per June 2023, Opensea's proxy contracts are:
    //Polygon: 0x58807baD0B376efc12F5AD86aAc70E78ed67deaE
    //Ethereum: 0xa5409ec958c83c3f309868babaca7c86dcb077c1

    constructor(
        string memory name,
        string memory symbol,
        string memory initialContractURI,
        address initialRoyaltyRecipient
    )
        ERC721(name, symbol)
    {
        _contractURI = initialContractURI;
        _royaltyRecipient = initialRoyaltyRecipient;
        _whitelist[0x58807baD0B376efc12F5AD86aAc70E78ed67deaE] = true; // Initialize the whitelist with the OpenSea proxy address
    }

    function setContractURI(string memory newURI) public onlyOwner {
        _contractURI = newURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
        // SafeMint function with Checks-Effects-Interactions pattern
    function safeMint(address to, uint256 tokenId, string memory uri) public {
        require(hasRole(MINTER_ROLE, msgSender()), "Caller is not a minter");
        require(!_exists(tokenId), "Token ID already in use");

        string memory _uri = uri; // Store the URI first (Effect)
        if (msgSender() == owner()) {
            _safeMint(to, tokenId); // Interaction
            _setTokenURI(tokenId, _uri); // Effect
        } else {
            require(
                tokenId >= _minterRanges[msgSender()].minTokenId && tokenId <= _minterRanges[msgSender()].maxTokenId,
                "Token ID outside of minter's range"
            );
            _safeMint(to, tokenId); // Interaction
            _setTokenURI(tokenId, _uri); // Effect
        }
        emit Mint(to, tokenId, _uri); // Interaction (Event Emission)
    }

    struct MintingRange {
        uint256 minTokenId;
        uint256 maxTokenId;
    }

    mapping(address => MintingRange) private _minterRanges;

    function grantMinterRole(address minter, uint256 minTokenId, uint256 maxTokenId) public onlyOwner {
        require(minter != address(0), "Minter cannot be zero address");
        grantRole(MINTER_ROLE, minter);
        _minterRanges[minter] = MintingRange(minTokenId, maxTokenId);
        emit MinterRoleGranted(minter, minTokenId, maxTokenId);
    }

    function setRoyaltyRecipient(address newRoyaltyRecipient) public onlyOwner {
        require(newRoyaltyRecipient != address(0), "New royalty recipient cannot be the zero address");
        _royaltyRecipient = newRoyaltyRecipient;
        emit RoyaltyRecipientChanged(newRoyaltyRecipient);
    }

    function revokeMinterRole(address minter) public onlyOwner {
        require(minter != msgSender(), "Owner cannot revoke their own minter role");
        revokeRole(MINTER_ROLE, minter);
        delete _minterRanges[minter]; // remove minting range when minter role is revoked
        emit MinterRoleRevoked(minter);
    }

    address private _royaltyRecipient;
    uint256 private _royaltyPercentage = 5 * 10 ** 16; // 5%

    function setRoyaltyPercentage(uint256 newPercentage) public onlyOwner {
        require(newPercentage <= 10**18, "Percentage cannot exceed 100%");
        _royaltyPercentage = newPercentage;
    }

    function royaltyInfo(uint256 /*tokenId*/, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _royaltyRecipient;
        royaltyAmount = (salePrice * _royaltyPercentage) / 10**18;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage, AccessControl, IERC165)
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }

    function addWhitelistAddress(address addr) public onlyOwner {
        _whitelist[addr] = true;
    }

    function removeWhitelistAddress(address addr) public onlyOwner {
        _whitelist[addr] = false;
    }

    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
        if (_whitelist[_operator]) {
            return true;
        }
        return super.isApprovedForAll(_owner, _operator);
    }
}