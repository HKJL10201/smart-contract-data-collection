// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma abicoder v2;

/// @dev for remix testing uncomment github import and comment other one.
// import "https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
// import "https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract ExitPoolUniswap {
    // Address for Contract Functions & Tokens
    address public nonfungiblePositionManagerAddress =
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address public LINK = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address public WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    uint24 public poolFee = 3000;
    address public userAddress;

    INonfungiblePositionManager public immutable nonfungiblePositionManager;
    // Struct for User deposits
    struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
    }

    // deposits[tokenId] => Deposit
    mapping(uint256 => Deposit) public deposits;

    // Constructor
    constructor() {
        userAddress = msg.sender;
        nonfungiblePositionManager = INonfungiblePositionManager(
            nonfungiblePositionManagerAddress
        );
    }

    /// @notice We know that Uniswap V3 uses NFT to manage and represent the Liquidity Pool so we need to access the ERC721 tokens from the sender's wallet.
    /// @dev Function to execute on recieving permissions
    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        require(
            msg.sender == address(nonfungiblePositionManagerAddress),
            "not a univ3 nft"
        );
        _createDeposit(operator, tokenId);
        return this.onERC721Received.selector;
    }

    /// @notice To create the deposit by adding the values to the struct
    /// @dev To create a deposit
    function _createDeposit(address owner, uint256 tokenId) internal {
        (
            ,
            ,
            address token0,
            address token1,
            ,
            ,
            ,
            uint128 liquidity,
            ,
            ,
            ,

        ) = nonfungiblePositionManager.positions(tokenId);
        // set the owner and data for position
        deposits[tokenId] = Deposit({
            owner: owner,
            liquidity: liquidity,
            token0: token0,
            token1: token1
        });
    }

    /// @notice Now we will need a function to eliminate the liquidity and transfer the funds to the user.
    /// @dev Function to exit the liquidity and transfer all the funds back to the user
    function exitLiquidity(uint256 tokenId)
        external
        returns (uint256 amount0, uint256 amount1)
    {
        require(msg.sender == deposits[tokenId].owner, "Not the owner");
        uint128 liquidity = deposits[tokenId].liquidity;
        uint128 reqLiquidity = 0;

        // amount0Min and amount1Min are price slippage checks
        // if the amount received after burning is not greater than these minimums, transaction will fail
        INonfungiblePositionManager.DecreaseLiquidityParams
            memory params = INonfungiblePositionManager
                .DecreaseLiquidityParams({
                    tokenId: tokenId,
                    liquidity: reqLiquidity,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                });

        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(
            params
        );

        // send liquidity back to owner
        _sendToOwner(tokenId, amount0, amount1);
    }

    /// @notice To send the tokens to the owner
    function _sendToOwner(
        uint256 tokenId,
        uint256 amount0,
        uint256 amount1
    ) private {
        // get owner of contract
        address owner = deposits[tokenId].owner;

        address token0 = deposits[tokenId].token0;
        address token1 = deposits[tokenId].token1;
        // send collected fees to owner
        TransferHelper.safeTransfer(token0, owner, amount0);
        TransferHelper.safeTransfer(token1, owner, amount1);
    }
}
