// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title AuctionERC20
 * @author ggulaman
 * @notice Smart Contract (SC) which generates the ERC20 tokens
 */
contract AuctionERC20 is ERC20 {
    /**
     * @dev Constructor that gives the passed address all of existing tokens.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address _auctionAddress
    ) ERC20(_name, _symbol) {
        _mint(_auctionAddress, _initialSupply);
    }
}