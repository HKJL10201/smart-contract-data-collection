// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "./nft_explorer.sol";
import "./user.sol";

contract XpToken is Ownable, ERC1155, ERC1155Burnable {
    uint256 public constant XP = 0;
    address public _accountZero = 0x55f58b0241728459aC1F26613d4EE6D439A9e7A2; //WALLET WHICH TOKENS DUMP AT --- !!0
    address public _nftExplorerAddress; //NFT EXPLORER ADDRESS SAVES HERE(!!2) --- !!1
    address public _userContractAddress; //USER CONTRACT ADDRESS SAVES HERE(!!2) ---

    constructor() ERC1155("") {}

    function assign_xp(
        address to,
        uint256 amount,
        uint16 g_code
    ) public onlyOwner {
        if (_mint(to, XP, amount, "")) {
            user(_userContractAddress).AddXpToGainHistory(to, g_code, amount);
        }
    }

    function assign_xp_toNFT(
        address from,
        uint256 nftID,
        uint256 amount
    ) public {
        require(amount <= balance_xp(from), "XP amount exceeds balance");
        if (nft_explorer(_nftExplorerAddress).xpToNFT(from, nftID, amount)) {
            transfer(from, amount, 9999);
        }
    }

    function balance_xp(address account) public view returns (uint256 amount) {
        return balanceOf(account, XP);
    }

    function transfer(
        address from,
        uint256 amount,
        uint16 b_code
    ) public {
        require(
            from == _msgSender(),
            "ERC1155: caller is not token owner nor approved"
        );
        if (balanceOf(from, XP) >= amount) {
            safeTransferFrom(from, _accountZero, XP, amount, "");
            user(_userContractAddress).AddXpToBurnList(from, b_code, amount);
        }
    }

    ////////////////////////////////////////////THIS FUNCTION IS JUST FOR TEST PURPOSES(!!1) --- !!2
    function setNftExplorerAddress(address nft_explorer_address)
        public
        onlyOwner
    {
        _nftExplorerAddress = nft_explorer_address;
    }

    function setUserAddress(address user_contract_address) public onlyOwner {
        _userContractAddress = user_contract_address;
    }
}

///////////////CONTRACT IS TO LONG WE SHOULD USE A SEPERATE CONTRACT FOR HISTORY AND INFORMATION --- !!7
