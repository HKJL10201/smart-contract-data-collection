pragma solidity ^0.8.0;

import "https://github.com/aave/protocol-v2/blob/master/contracts/interfaces/ILendingPool.sol";
import "https://github.com/aave/protocol-v2/blob/master/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract FlashLoanArbitrage {

    address owner;

    ILendingPoolAddressesProvider provider;
    IUniswapV2Router02 uniswapRouter;
    IERC20 dai;
    IERC20 usdc;
    address ethAddress;

    constructor(ILendingPoolAddressesProvider _provider, IUniswapV2Router02 _uniswapRouter, IERC20 _dai, IERC20 _usdc, address _ethAddress) {
        owner = msg.sender;
        provider = _provider;
        uniswapRouter = _uniswapRouter;
        dai = _dai;
        usdc = _usdc;
        ethAddress = _ethAddress;
    }

    function startArbitrage(uint256 amount) external {
        require(msg.sender == owner, "Only the contract owner can execute this function");
        address receiverAddress = address(this);
        address[] memory assets = new address[](1);
        assets[0] = address(dai);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
        lendingPool.flashLoan(address(this), assets, amounts, modes, receiverAddress, address(0), 0, "");
    }

    function executeArbitrage(uint256 amount, uint256 amountToRepay) external {
        uint256 balanceDai = dai.balanceOf(address(this));
        require(balanceDai >= amount, "Not enough DAI to execute the arbitrage");

        uint256 balanceEth = address(this).balance;
        require(balanceEth >= amountToRepay, "Not enough ETH to repay the flash loan");

        // Swap DAI for USDC on Uniswap
        address[] memory path = new address[](2);
        path[0] = address(dai);
        path[1] = address(usdc);
        dai.approve(address(uniswapRouter), amount);
        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp)[1];
        uint256 amountUSDC = amounts[amounts.length - 1];

        // Swap USDC for ETH on Uniswap
        path[0] = address(usdc);
        path[1] = ethAddress;
        usdc.approve(address(uniswapRouter), amountUSDC);
        uniswapRouter.swapExactTokensForETH(amountUSDC, 0, path, address(this), block.timestamp);

        // Repay Flash Loan
        dai.transfer(msg.sender, amountToRepay);
    }

    function withdrawTokens(IERC20 token, uint256 amount) external {
        require(msg.sender == owner, "Only the contract owner can execute this function");
        token.transfer(msg.sender, amount);
    }

    function withdrawETH() external {
        require(msg.sender == owner, "Only the contract owner can execute this function");
        payable(msg.sender).transfer(address(this).balance);
    }
}
