// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Interfaces
import './interfaces/IUbeswapPathManager.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IUniswapV2Factory.sol';
import "./interfaces/IBackupMode.sol";

//OpenZeppelin
import "./openzeppelin-solidity/contracts/ERC20/SafeERC20.sol";
import "./openzeppelin-solidity/contracts/ERC20/IERC20.sol";

//Inheritance
import './interfaces/IRouter.sol';

contract Router is IRouter {
    using SafeERC20 for IERC20;

    IUbeswapPathManager public immutable pathManager;
    IUniswapV2Router02 public immutable ubeswapRouter;
    IUniswapV2Factory public immutable ubeswapFactory;
    IERC20 public immutable TGEN;

    constructor(address _ubeswapPathManagerAddress, address _ubeswapRouter, address _ubeswapFactory, address _TGEN) {
        require(_ubeswapPathManagerAddress != address(0), "Router: invalid address for UbeswapPathManager.");
        require(_ubeswapRouter != address(0), "Router: invalid address for Ubeswap router.");
        require(_ubeswapFactory != address(0), "Router: invalid address for Ubeswap factory.");
        require(_TGEN != address(0), "Router: invalid address for TGEN.");

        pathManager = IUbeswapPathManager(_ubeswapPathManagerAddress);
        ubeswapRouter = IUniswapV2Router02(_ubeswapRouter);
        ubeswapFactory = IUniswapV2Factory(_ubeswapFactory);
        TGEN = IERC20(_TGEN);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @dev Swaps the given asset for TGEN.
    * @notice Need to set (asset => TGEN) path in UbeswapPathManager before calling this function.
    * @notice Need to transfer asset to Swap contract before calling this function.
    * @param _asset Address of token to swap from.
    * @param _amount Number of tokens to swap.
    * @param (uint256) Amount of TGEN received.
    */
    function swapAssetForTGEN(address _asset, uint256 _amount) external override returns (uint256) {
        require(_asset != address(0), "Router: invalid asset address.");
        require(_amount > 0, "Router: amount must be positive.");

        IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(_asset).approve(address(ubeswapRouter), _amount);

        address[] memory path = pathManager.getPath(_asset, address(TGEN));
        uint256[] memory amounts = ubeswapRouter.swapExactTokensForTokens(_amount, 0, path, msg.sender, block.timestamp + 10000);

        emit SwappedForTGEN(_asset, _amount, amounts[amounts.length - 1]);

        return amounts[amounts.length - 1];
    }

    /**
    * @dev Swaps TGEN for the given asset.
    * @notice Need to transfer TGEN to Router contract before calling this function.
    * @param _asset Address of token to swap to.
    * @param _amount Number of TGEN to swap.
    * @param (uint256) Amount of asset received.
    */
    function swapTGENForAsset(address _asset, uint256 _amount) external override returns (uint256) {
        require(_asset != address(0), "Router: invalid asset address.");
        require(_amount > 0, "Router: amount must be positive.");

        TGEN.safeTransferFrom(msg.sender, address(this), _amount);
        TGEN.approve(address(ubeswapRouter), _amount);

        address[] memory path = pathManager.getPath(address(TGEN), _asset);
        uint256[] memory amounts = ubeswapRouter.swapExactTokensForTokens(_amount, 0, path, msg.sender, block.timestamp + 10000);

        emit SwappedFromTGEN(_asset, _amount, amounts[amounts.length - 1]);

        return amounts[amounts.length - 1];
    }

    /**
    * @dev Adds liquidity for asset-TGEN pair.
    * @notice Need to transfer asset and TGEN to Router contract before calling this function.
    * @notice Assumes the _amountAsset and _amountTGEN has equal dollar value.
    * @notice This function is meant to be called from the LiquidityBond contract.
    * @param _asset Address of other token.
    * @param _amountAsset Amount of other token to add.
    * @param _amountTGEN Amount of TGEN to add.
    * @return (uint256) Number of LP tokens received.
    */
    function addLiquidity(address _asset, uint256 _amountAsset, uint256 _amountTGEN) external override returns (uint256) {
        require(_asset != address(0), "Router: invalid asset address.");
        require(_amountAsset > 0, "Router: amountAsset must be positive.");
        require(_amountTGEN > 0, "Router: amountTGEN must be positive.");

        TGEN.safeTransferFrom(msg.sender, address(this), _amountTGEN);
        TGEN.approve(address(ubeswapRouter), _amountTGEN);

        IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amountAsset);
        IERC20(_asset).approve(address(ubeswapRouter), _amountAsset);

        (,, uint256 numberOfLPTokens) = ubeswapRouter.addLiquidity(address(TGEN), _asset, _amountTGEN, _amountAsset, 0, 0, msg.sender, block.timestamp + 10000);

        emit AddedLiquidity(_asset, _amountAsset, _amountTGEN, numberOfLPTokens);

        return numberOfLPTokens;
    }

    /**
    * @dev Removes liquidity for asset-TGEN pair.
    * @notice Need to transfer LP tokens to Router contract before calling this function.
    * @notice This function is meant to be called from the LiquidityBond contract.
    * @param _asset Address of other token.
    * @param _numberOfLPTokens Number of LP tokens to remove.
    * @return (uint256, uint256) Amount of token0 received, and amount of token1 received.
    */
    function removeLiquidity(address _asset, uint256 _numberOfLPTokens) external override returns (uint256, uint256) {
        require(_asset != address(0), "Router: invalid asset address.");
        require(_numberOfLPTokens > 0, "Router: number of LP tokens must be positive.");

        IERC20 pair = IERC20(ubeswapFactory.getPair(_asset, address(TGEN)));

        pair.safeTransferFrom(msg.sender, address(this), _numberOfLPTokens);
        pair.approve(address(ubeswapRouter), _numberOfLPTokens);

        (uint256 amountA, uint256 amountB) = ubeswapRouter.removeLiquidity(address(TGEN), _asset, _numberOfLPTokens, 0, 0, msg.sender, block.timestamp + 10000);

        emit RemovedLiquidity(_asset, _numberOfLPTokens, amountA, amountB);

        return (amountA, amountB);
    }

    /* ========== EVENTS ========== */

    event SwappedForTGEN(address asset, uint256 amountOfTokensSwapped, uint256 amountOfTGENReceived);
    event SwappedFromTGEN(address asset, uint256 amountOfTGENSwapped, uint256 amountOfTokensReceived);
    event AddedLiquidity(address asset, uint256 amountAsset, uint256 amountTGEN, uint256 numberOfLPTokens);
    event RemovedLiquidity(address asset, uint256 numberOfLPTokens, uint256 amountAReceived, uint256 amountBReceived);
}