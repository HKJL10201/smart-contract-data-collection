// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IUniswapV2Router02.sol";

contract Fund is ERC20, Ownable {
    IUniswapV2Router02 public immutable uniswapV2Router;

    struct Asset {
        address token;
        uint256 amount;
    }

    Asset[] public assets;

    constructor(
        string memory _name,
        string memory _symbol,
        address _router,
        address[] memory tokens,
        uint256[] memory amounts
    ) ERC20(_name, _symbol) {
        uniswapV2Router = IUniswapV2Router02(_router);
        // Don't think you can pass in structs as arg
        for (uint256 i = 0; i < tokens.length; i++) {
            assets.push(Asset(tokens[i], amounts[i]));
        }
    }

    function join(uint256 qty) external payable {
        for (uint256 i = 0; i < assets.length; i++) {
            Asset memory _asset = assets[i];

            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = _asset.token;

            uint256 desired = qty * _asset.amount;

            uniswapV2Router.swapETHForExactTokens{value: address(this).balance}(
                desired,
                path,
                address(this),
                block.timestamp
            ); // add swapped eth to eth variable
        }
        Address.sendValue(payable(msg.sender), address(this).balance);
        _mint(msg.sender, qty);
    }

    // Calculate tokens based on exit. Call swapExactTokensForETH
    function exit(uint256 qty) external {
        _burn(msg.sender, qty);

        for (uint256 i = 0; i < assets.length; i++) {
            Asset memory _asset = assets[i];

            address[] memory path = new address[](2);
            path[0] = _asset.token;
            path[1] = uniswapV2Router.WETH();

            uint256 desired = qty * _asset.amount;

            IERC20(_asset.token).approve(address(uniswapV2Router), desired);

            uniswapV2Router.swapExactTokensForETH(
                desired,
                0, // accept any amount of ETH
                path,
                msg.sender,
                block.timestamp
            );
        }
    }

    receive() external payable {}
}
