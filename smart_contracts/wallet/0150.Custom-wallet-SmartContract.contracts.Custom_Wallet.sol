// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "hardhat/console.sol";

contract Custom_Wallet is Ownable {

    IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    function depositToken(address _token, uint _amount) external {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
    }


    function withdrawToken(address _token, uint _amount) external onlyOwner {
        uint contractBalance = IERC20(_token).balanceOf(address(this));
        require(contractBalance >= _amount, "Not enough to withdraw");
        IERC20(_token).transfer(msg.sender, _amount);
    }


    function withdrawETH(uint _amount) external onlyOwner {
        require(address (this).balance >= _amount, "This contract dont hold enough ETH to withdraw");
        payable(msg.sender).transfer(_amount);
    }


    function getBalanceOfToken(address _token) public view returns (uint){
        return IERC20(_token).balanceOf(address(this));
    }

    function getBalanceETH() external view returns(uint){
        return address(this).balance;
    }



            // Swap ETH in Tokens
    function swapETHForTokens(address _tokenOut, uint _amountIn) external payable onlyOwner {
        require(address(this).balance >= _amountIn, "Not enough ETH in contract to perform this swap");
        uint amountOutMin = getAmountOut(_amountIn, _tokenOut, SwapDirection.Weth_to_Tokens);
        amountOutMin = amountOutMin * 99 / 100;
        address [] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = _tokenOut;

        uniswapRouter.swapExactETHForTokens{value: _amountIn}(
            amountOutMin,
            path,
            address(this),
            block.timestamp + 120 //  Transaction must be done in 2 minutes.
        );
    }
            // Swap Token in ETH
    function swapTokensforETH(address _tokenIn, uint _amountIn) external onlyOwner {
        require(getBalanceOfToken(_tokenIn) >= _amountIn, "Not enough of this token in contract to perform this swap");
        uint amountOutMin = getAmountOut(_amountIn, _tokenIn, SwapDirection.Tokens_to_Weth);
        amountOutMin = amountOutMin * 99 / 100;
        address [] memory path = new address[](2);
        path[0]  = _tokenIn;
        path[1]  =uniswapRouter.WETH();

        IERC20(_tokenIn).approve(address (uniswapRouter), _amountIn);

        uniswapRouter.swapExactTokensForETH(
            _amountIn,
            amountOutMin,
            path,
            address(this),
            block.timestamp + 120 // Transaction must be done in 2 minutes.
        );
    }
        // To get the right amount out in which to swap is executed.
    enum SwapDirection {Tokens_to_Weth, Weth_to_Tokens}

    function getAmountOut(uint amountIn, address _tokenIn, SwapDirection direction) internal view returns (uint amountOut) {
        address[] memory path = new address[](2);


        if(direction == SwapDirection.Tokens_to_Weth){
            path[0] = _tokenIn;
            path[1] = uniswapRouter.WETH();
        }else if(direction == SwapDirection.Weth_to_Tokens){
            path[0] = uniswapRouter.WETH();
            path[1] = _tokenIn;
        }

        uint[] memory amounts = uniswapRouter.getAmountsOut(amountIn, path);
        return amounts[1];
    }

    receive() external payable{}
}
