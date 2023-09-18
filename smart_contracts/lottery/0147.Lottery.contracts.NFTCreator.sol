// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

contract NFTCreator is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC2981Upgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    RoyaltyInfo public defaultRoyaltyInfo;

    /**
     *  @notice FIXED_PRICE is price of each NFT sold
     */
    uint256 public constant FIXED_PRICE = 1e16;

    /**
     *  @notice _tokenCounter uint256 (counter). This is the counter for store
     *          current token ID value in storage.
     */
    uint256 public _tokenCounter;

    /**
     *  @notice treasury store the address of the TreasuryManager contract
     */
    address public treasury;

    /**
     *  @notice _admins mapping from token ID to isAdmin status
     */
    mapping(address => bool) public _admins;

    /**
     *  @notice uris mapping from token ID to token uri
     */
    mapping(uint256 => string) public uris;

    event SetTreasury(address indexed oldTreasury, address indexed newTreasury);
    event Bought(
        uint256 indexed tokenId,
        address indexed to,
        uint256 indexed timestamp
    );
    event Minted(
        uint256 indexed tokenId,
        address indexed to,
        uint256 indexed timestamp
    );
    event SetAdmin(address indexed user, bool indexed allow);

    modifier onlyAdmin() {
        require(
            (owner() == _msgSender() || _admins[_msgSender()]),
            "Ownable: caller is not an admin"
        );
        _;
    }

    /**
     *  @notice Return token URI.
     */
    function _tokenUri(uint256 tokenId) public view returns (string memory) {
        return uris[tokenId];
    }

    /**
     *  @notice Set new uri for each token ID
     */
    function setTokenURI(string memory newURI, uint256 tokenId)
        public
        onlyOwner
    {
        uris[tokenId] = newURI;
    }

    /**
     *  @notice Mapping token ID to base URI in ipfs storage
     *
     *  @dev    All caller can call this function.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token."
        );

        string memory currentURI = _tokenUri(tokenId);

        return
            bytes(currentURI).length > 0
                ? string(abi.encodePacked(currentURI, ".json"))
                : ".json";
    }

    /**
     *  @notice Initialize new logic contract.
     */
    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _treasury,
        uint96 _feeNumerator
    ) public initializer {
        ERC721Upgradeable.__ERC721_init(_name, _symbol);
        OwnableUpgradeable.__Ownable_init();
        transferOwnership(_owner);
        treasury = _treasury;
        _setDefaultRoyalty(_treasury, _feeNumerator);
        defaultRoyaltyInfo = RoyaltyInfo(_treasury, _feeNumerator);
    }

    /**
     *  @notice Check account whether it is the admin role.
     *
     *  @dev    All caller can call this function.
     */
    function isAdmin(address account) public view returns (bool) {
        return _admins[account];
    }

    /**
     *  @notice Replace the admin role by another address.
     *
     *  @dev    Only owner can call this function.
     */
    function setAdmin(address user, bool allow) public onlyOwner {
        _admins[user] = allow;
        emit SetAdmin(user, allow);
    }

    /**
     *  @notice set treasury to change TreasuryManager address.
     *
     *  @dev    Only admin can call this function.
     */
    function setTreasury(address account) public onlyOwner {
        address oldTreasury = treasury;
        treasury = account;
        emit SetTreasury(oldTreasury, treasury);
    }

    /**
     *  @notice Buy NFT directly
     *
     *  @dev    All users can call this function.
     */
    function buy() public payable nonReentrant {
        require(
            msg.value == FIXED_PRICE,
            "Payment not equal to ETH price to pay !"
        );
        uint256 tokenId = _tokenCounter;
        _mint(_msgSender(), tokenId);
        _tokenCounter++;

        emit Bought(tokenId, _msgSender(), block.timestamp);
    }

    /**
     *  @notice Mint NFT not pay token
     *
     *  @dev    Only admin can call this function.
     */
    function mint(address receiver) public onlyAdmin {
        uint256 tokenId = _tokenCounter;

        _mint(receiver, tokenId);
        _tokenCounter++;

        emit Minted(tokenId, receiver, block.timestamp);
    }

    /**
     * @dev See {IERC165-supportsInterface} override for ERC2981Upgradeable, ERC721EnumerableUpgradeable
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721EnumerableUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
