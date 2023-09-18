//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ColorModifiers is ERC1155, Ownable {
    uint256 public constant DARKPAINT = 0;
    uint256 public constant WHITEPAINT = 1;

    // struct RGB {
    //     uint256 R;
    //     uint256 G;
    //     uint256 B;
    // }

    address jackpotAddress;

    uint256 public mintPrice = 0.00001 ether;

    constructor(address _jackpotAddress)
        ERC1155("https://game.example/api/item{id}.json")
    {
        jackpotAddress = _jackpotAddress;
    }

    function name() public pure returns (string memory) {
        return "ColorModifiers";
    }

    function symbol() public pure returns (string memory) {
        return "CLRMODIF";
    }

    function getBalanceDarkPaint(address owner) public view returns (uint256) {
        return balanceOf(owner, 0);
    }

    function getBalanceWhitePaint(address owner) public view returns (uint256) {
        return balanceOf(owner, 1);
    }

    // this one for free
    function mint() public {
        // make it payable
        _mint(msg.sender, DARKPAINT, 2, "");
        _mint(msg.sender, WHITEPAINT, 2, "");
        // transfer to jackpot address
        //
    }

    // this one costs and sends money to jackpotAddress

    function mintPayable(uint256 tokenId, uint256 amount) external payable {
        // make it payable
        require(msg.value == mintPrice * amount, "wrong value");
        _mint(msg.sender, tokenId, amount, "");
        address payable jackpotWallet = payable(jackpotAddress);
        (bool success, ) = jackpotWallet.call{value: address(this).balance}("");
        require(success, "Transfer to jackpot");
        // jackpotWallet.transfer(address(this).balance);
    }

    //     function mint () external payable {
    //                       require (isMintEnabled, "minting not enabled");
    //                       require(mintedWallets[msg.sender] < 2, "exceeds max per wallet");
    //                       require(msg.value == mintPrice, "wrong value");
    //                       require(maxSupply > totalSupply, "sold out");

    //                       mintedWallets[msg.sender]++;
    //                       totalSupply++;
    //                       uint256 tokenId = totalSupply;
    //                       _safeMint(msg.sender, tokenId);

    //    }
}
