// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity ^0.8.12;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BAP_APES is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string baseURI;

    uint256 public maxSupply = 10000;
    uint256 public mintLimit = 2;
    uint256 public publicSupply = 3500; // Public Minting
    uint256 public reservedSuply = 5000; // 5000 Portal Passes
    uint256 public trasurySuply = 1500; // Treasury reserved supply

    uint256[] public tierPrices = [
        0.22 ether,
        0.27 ether,
        0.3 ether,
        0.33 ether,
        0.33 ether,
        0.37 ether
    ];

    IERC1155 public portalPass;

    address public secret;
    address public treasury;
    address private constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    mapping(uint256 => uint256) public mintingPrice;
    mapping(uint256 => uint256) public mintingDate;

    mapping(uint256 => bool) public notRefundable;

    mapping(address => bool) public isOrchestrator;

    mapping(address => mapping(uint256 => uint256)) public walletMinted;

    event Purchased(address operator, address user, uint256 amount);
    event PassExchanged(address operator, address user, uint256 amount);
    event Airdrop(address operator, address user, uint256 amount);
    event TraitsChanged(address user, uint256 tokenId, uint256 newTokenId);
    event Refunded(address user, uint256 tokenId);

    constructor(address _portalPass, address _secret)
        ERC721("BAP APES", "APES")
    {
        portalPass = IERC1155(_portalPass);
        secret = _secret;
    }

    modifier onlyOrchestrator() {
        require(isOrchestrator[msg.sender], "Operator not allowed");
        _;
    }

    function purchase(
        address to,
        uint256 amount,
        uint256 tier,
        bytes memory signature
    ) external payable {
        require(tier <= 5, "Purchase: Sale closed");
        require(amount <= publicSupply, "Purchase: Supply is over");
        require(
            amount + walletMinted[to][tier] <= mintLimit,
            "Purchase: Exceed mint limit"
        );
        require(
            amount * tierPrices[tier] == msg.value,
            "Purchase: Incorrect ETH amount"
        );

        require(
            _verifyHashSignature(
                keccak256(abi.encode(amount, tier, to)),
                signature
            ),
            "Purchase: Signature is invalid"
        );

        walletMinted[to][tier] += amount;
        publicSupply -= amount;

        mint(to, amount, tierPrices[tier]);

        emit Purchased(msg.sender, to, amount);
    }

    function airdrop(address to, uint256 amount)
        external
        nonReentrant
        onlyOwner
    {
        require(amount <= trasurySuply, "Airdrop: Supply is over");

        trasurySuply -= amount;

        mint(to, amount, 0);

        emit Airdrop(msg.sender, to, amount);
    }

    function exchangePass(address to, uint256 amount) external {
        require(amount <= reservedSuply, "Pass Exchange: Supply is over");

        portalPass.safeTransferFrom(
            msg.sender,
            DEAD_ADDRESS,
            1,
            amount,
            "0x00"
        );

        reservedSuply -= amount;

        mint(to, amount, tierPrices[0]);

        emit PassExchanged(msg.sender, to, amount);
    }

    function confirmChange(uint256 tokenId) external onlyOrchestrator {
        address owner = ownerOf(tokenId);

        _burn(tokenId);

        uint256 newId = tokenId + 10000;
        _safeMint(owner, newId);

        emit TraitsChanged(owner, tokenId, newId);
    }

    function mint(
        address to,
        uint256 amount,
        uint256 price
    ) internal {
        uint256 currentSupply = totalSupply();

        require(amount + currentSupply <= maxSupply, "Mint: Supply limit");

        for (uint256 i = 1; i <= amount; i++) {
            uint256 id = currentSupply + i;
            mintingPrice[id] = price;
            mintingDate[id] = block.timestamp;
            _safeMint(to, id);
        }
    }

    function refund(address depositAddress, uint256 tokenId)
        external
        onlyOrchestrator
    {
        uint256 balance = mintingPrice[tokenId];
        require(balance > 0, "Refund: Original Minting Price is zero");
        require(
            !notRefundable[tokenId],
            "Refund: The token is not available for refund"
        );
        require(
            ownerOf(tokenId) == depositAddress,
            "Refund: Address is not the token owner"
        );

        _transfer(depositAddress, treasury, tokenId);

        (bool success, ) = depositAddress.call{value: balance}("");

        emit Refunded(depositAddress, tokenId);
    }

    function setMintLimit(uint256 newLimit) external onlyOwner {
        mintLimit = newLimit;
    }

    function setBaseURI(string memory newURI) external onlyOwner {
        baseURI = newURI;
    }

    function setSecret(address _secret) external onlyOwner {
        secret = _secret;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setPortalPass(address _portalPass) external onlyOwner {
        portalPass = IERC1155(_portalPass);
    }

    function setOrchestrator(address operator, bool status) external onlyOwner {
        isOrchestrator[operator] = status;
    }

    function withdrawETH(address _address, uint256 amount)
        public
        nonReentrant
        onlyOwner
    {
        require(amount <= address(this).balance, "Insufficient funds");
        (bool success, ) = _address.call{value: amount}("");

        require(success, "Unable to send eth");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        _checkTransferPeriod(tokenId);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        _checkTransferPeriod(tokenId);
        super.safeTransferFrom(from, to, tokenId, "");
    }

    function _checkTransferPeriod(uint256 tokenId) internal {
        if (
            block.timestamp > mintingDate[tokenId] + 3 hours &&
            !notRefundable[tokenId]
        ) {
            notRefundable[tokenId] = true;
        }
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function _verifyHashSignature(bytes32 freshHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address signer = address(0);
        if (v == 27 || v == 28) {
            // solium-disable-next-line arg-overflow
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }
}
