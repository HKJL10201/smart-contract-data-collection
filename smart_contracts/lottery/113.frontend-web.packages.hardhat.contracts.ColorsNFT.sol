//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract ColorsNFT is ERC721, ERC1155Holder, Ownable {
    // ERC721 variables
    uint256 public mintPrice = 0.001 ether;
    uint256 public totalSupply;
    uint256 public maxSupply;
    bool public isMintEnabled = true;
    mapping(address => uint256) public mintedTokens;

    mapping(uint256 => uint256) public tokenToColor;

    mapping(address => uint256[]) public ownerToTokens;
    mapping(uint256 => address payable) public tokenToOwner;
    address jackpotAddress;
    // struct RGB {
    //     uint256 R;
    //     uint256 G;
    //     uint256 B;
    // }
    uint256[] public colorTokenList;

    // event RGBChanged(uint256 tokenId, RGB newRGB);

    // ERC1155 mapping (how much of each color modifier it has)

    address colorModifiersAddress;

    mapping(uint256 => mapping(uint256 => uint256))
        private supplyAmountsForColor;

    uint256 public constant DARKPAINT = 0;
    uint256 public constant WHITEPAINT = 1;

    //Constructor and functions

    constructor(address _colorModifiersAddress, address _jackpotAddress)
        payable
        ERC721("Colomint", "COLO")
    {
        jackpotAddress = _jackpotAddress;
        maxSupply = 10 * 16;
        colorModifiersAddress = _colorModifiersAddress;
    }

    function toggleIsMintenabled() external onlyOwner {
        isMintEnabled = !isMintEnabled;
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function mint() external payable {
        require(isMintEnabled, "minting not enabled");
        require(mintedTokens[msg.sender] < 5, "exceeds max per wallet");
        require(msg.value == mintPrice, "wrong value");
        require(maxSupply > totalSupply, "sold out");

        mintInternal(
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        totalSupply
                    )
                )
            ) % (2**24)
        );

        // send to jackpotwallet
        address payable jackpotWallet = payable(jackpotAddress);
        (bool success, ) = jackpotWallet.call{value: address(this).balance}("");
        require(success, "Transfer to jackpot failed");
    }

    // TODO make this private before going to production!
    function mintInternal(uint256 rgbInt) public {
        mintedTokens[msg.sender]++;
        totalSupply++;
        uint256 tokenId = totalSupply;
        _safeMint(msg.sender, tokenId);

        tokenToColor[tokenId - 1] = rgbInt;

        // owner and Tokens relations
        ownerToTokens[msg.sender].push(tokenId - 1);
        tokenToOwner[tokenId - 1] = payable(msg.sender);

        // list of nfts with their colors
        colorTokenList.push(rgbInt);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Receiver, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // receiving a color paint modifier
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) public override returns (bytes4) {
        require(
            msg.sender == colorModifiersAddress,
            "Only works with accepted ERC1155"
        );
        uint256 colorNFTId = toUint256(data); // check this
        supplyAmountsForColor[colorNFTId][id] += value;

        console.log("colorNFTId", colorNFTId);
        console.log("tokenID", id);

        if (id == DARKPAINT) {
            tokenToColor[colorNFTId] = (tokenToColor[colorNFTId] * 1) / 3;
        } else {
            tokenToColor[colorNFTId] = tokenToColor[colorNFTId] * 3;
        }

        colorTokenList[colorNFTId] = tokenToColor[colorNFTId];
        // emit RGBChanged(colorNFTId, tokenToColor[colorNFTId]);
        return
            bytes4(
                bytes4(
                    keccak256(
                        "onERC1155Received(address,address,uint256,uint256,bytes)"
                    )
                )
            );
    }

    function toUint256(bytes memory _bytes)
        internal
        pure
        returns (uint256 value)
    {
        assembly {
            value := mload(add(_bytes, 0x20))
        }
    }

    function rgbToInt(
        uint256 _r,
        uint256 _g,
        uint256 _b
    ) public pure returns (uint256) {
        uint256 rgb = 256**2 * _r + 256 * _g + _b; // Transform RGB into uint256

        return rgb;
    }

    function intToRgb(uint256 color)
        public
        pure
        returns (
            uint256 r,
            uint256 g,
            uint256 b
        )
    {
        uint256 _r = color / (256**2);
        uint256 _g = (color - _r * (256**2)) / 256;
        uint256 _b = color - _r * (256**2) - _g * 256;

        return (_r, _g, _b);
    }

    function colorDistance(uint256 colorOne, uint256 colorTwo)
        public
        pure
        returns (uint256 distance)
    {
        (uint256 rOne, uint256 gOne, uint256 bOne) = intToRgb(colorOne);
        (uint256 rTwo, uint256 gTwo, uint256 bTwo) = intToRgb(colorTwo);
        uint256 _distance = absDiff(rOne, rTwo) +
            absDiff(gOne, gTwo) +
            absDiff(bOne, bTwo);

        return _distance;
    }

    function absDiff(uint256 valueOne, uint256 valueTwo)
        public
        pure
        returns (uint256 absValue)
    {
        return valueOne >= valueTwo ? valueOne - valueTwo : valueTwo - valueOne;
    }

    function getColorsByOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        return ownerToTokens[_owner];
    }

    function _colorTokenList() public view returns (uint256[] memory) {
        return colorTokenList;
    }
}
