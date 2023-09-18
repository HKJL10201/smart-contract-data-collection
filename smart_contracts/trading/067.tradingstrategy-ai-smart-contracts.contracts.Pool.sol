
import "@openzeppelin/contracts-v4/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-v4/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-v4/security/ReentrancyGuard.sol";
import "./interfaces/IERC20Detailed.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IAaveLendingPool.sol";
import "./interfaces/AggregatorV3Interface.sol";


/**
    Trading strategy pool. Shareholders deposit funds, which are then traded or deposited into aave by the
    pool manager.

    Supports single shareholder for now. Needs shares functionality for deposit and withdraw to support multiple
    shareholders.

    Manager executes trade and deposit instructions.

    security note: modifiers currently disabled for demo purposes.
*/
contract Pool is ERC20, ReentrancyGuard {

    struct Asset {
        address asset;
    }

    Asset[] public supportedAssets;
    mapping(address => address) public priceOracles;

    address manager;
    address shareholder;

    /* EVENTS */

    event Deposit(
        address asset,
        uint amount
    );

    event Withdraw(

    );

    /* MODIFIERS */

    modifier onlyManager {
        require(msg.sender == manager, "Pool: Only manager");
        _;
    }


    modifier onlyShareholder {
        require(msg.sender == shareholder, "Pool: Only shareholder");
        _;
    }


    constructor(
        string memory name_,
        string memory symbol_,
        address _manager,
        address[] memory _supportedAssets,
        address[] memory _priceOracles,
        address _shareholder
    ) ERC20(name_, symbol_) {
        manager = _manager;
        shareholder = _shareholder;

        for (uint i = 0; i  < _supportedAssets.length; i++) {
            supportedAssets.push(Asset(_supportedAssets[i]));
            priceOracles[_supportedAssets[i]] = _priceOracles[i];
        }
    }


    function deposit(address _asset, uint256 _amount) external /* onlyShareholder */ {
        // TODO: reenable permissions; demo purpose only
        require(priceOracles[_asset] != address(0), "Asset not supported");

        uint256 fundValue = totalFundValue();

        uint256 totalSupplyBefore = totalSupply();

        require(IERC20Detailed(_asset).transferFrom(msg.sender, address(this), _amount), "token transfer failed");

        emit Deposit(_asset, _amount);
    }

    function withdraw() external /* onlyShareholder */ nonReentrant {
        // TODO: reenable permissions; demo purpose only

        // move all assets to shareholder
        for (uint i = 0; i < supportedAssets.length; i++) {
            IERC20Detailed asset = IERC20Detailed(supportedAssets[i].asset);
            asset.transfer(msg.sender, asset.balanceOf(address(this)));
        }

        emit Withdraw();
    }

    function totalFundValue() public view returns (uint256) {
        uint256 total = 0;
        uint256 assetCount = supportedAssets.length;

        for (uint256 i = 0; i < assetCount; i++) {
            total = total + assetValue(supportedAssets[i].asset);
        }
        return total;
    }

    function assetValue(address asset) public view returns (uint256 value) {
        value = assetValue(asset, assetBalance(asset));
    }

    function assetValue(address asset, uint256 amount) public view returns (uint256 value) {
        uint256 price = getAssetPrice(asset);
        uint256 decimals = assetDecimal(asset);

        value = price * amount / (10**decimals);
    }

    function getAssetPrice(address asset) public view returns (uint256 price) {
        AggregatorV3Interface aggregator = AggregatorV3Interface(priceOracles[asset]);

        // skipping checks for staleness
        (
            /* uint80 roundId */,
            int256 answer,
            /* uint256 startedAt */,
            /* uint256 updatedAt */,
            /* uint80 answeredInRound */
        ) = aggregator.latestRoundData();

        return uint256(answer);
    }

    function assetDecimal(address asset) public view returns (uint256 price) {
        return IERC20Detailed(asset).decimals();
    }

    function assetBalance(address asset) public view returns (uint256 balance) {
        return IERC20Detailed(asset).balanceOf(address(this));
    }

    function tokenPrice() external view returns (uint256 price) {
        uint256 fundValue = totalFundValue();
        uint256 tokenSupply = totalSupply();

        price = _tokenPrice(fundValue, tokenSupply);
    }

    function _tokenPrice(uint256 _fundValue, uint256 _tokenSupply) internal pure returns (uint256 price) {
        if (_tokenSupply == 0 || _fundValue == 0) return 0;

        price = _fundValue * 1e18 / _tokenSupply;
    }

    /* UNISWAPV2-LIKE SWAPS */

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        IUniswapV2Router02 router
    ) public /* onlyManager */ returns (uint[] memory amounts) {
        // TODO: reenable permissions; demo purpose only

        IERC20Detailed(path[0]).approve(address(router), amountIn);
        return router.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), block.timestamp);
    }

    /* 1INCH SWAP */


    struct OneInchSwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    function swapTokensOn1Inch(
        bytes calldata data,
        uint minOut,
        address aggregationRouterV3
    ) public /* onlyManager */ {
        // TODO: reenable permissions; demo purpose only

        (/* address _c */, OneInchSwapDescription memory desc, /* bytes memory _d */)
            = abi.decode(data[4:], (address, OneInchSwapDescription, bytes));

        desc.srcToken.approve(aggregationRouterV3, desc.amount);
        (bool succ, bytes memory _data) = address(aggregationRouterV3).call(data);
        if (succ) {
            (uint returnAmount, uint gasLeft) = abi.decode(_data, (uint, uint));
            require(returnAmount >= minOut);
        } else {
            revert("Failed to swap");
        }
    }

    /* AAVE DEPOSITS */

    function aaveDeposit(
        address asset,
        uint256 amount,
        IAaveLendingPool aaveLendingPool
    ) public /* onlyManager */ {
        // TODO: reenable permissions; demo purpose only

        IERC20Detailed(asset).approve(address(aaveLendingPool), amount);
        aaveLendingPool.deposit(asset, amount, address(this), 0);
    }

    function aaveWithdraw(
        address asset,
        uint256 amount,
        IAaveLendingPool aaveLendingPool
    ) public /* onlyManager */ {
        // TODO: reenable permissions; demo purpose only

        aaveLendingPool.withdraw(asset, amount, address(this));
    }


    /* COMBOS */

    function swapAndAaveDepositAll(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        IUniswapV2Router02 router,
        IAaveLendingPool aaveLendingPool
    ) public /* onlyManager */ {
        // TODO: reenable permissions; demo purpose only

        address outputAsset = path[1];
        uint balanceBefore = assetBalance(outputAsset);

        IERC20Detailed(path[0]).approve(address(router), amountIn);
        router.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), block.timestamp);

        uint balanceAfter = assetBalance(outputAsset);
        uint outputAmount = balanceAfter - balanceBefore;

        IERC20Detailed(path[1]).approve(address(aaveLendingPool), outputAmount);
        aaveLendingPool.deposit(path[1], outputAmount, address(this), 0);
    }

    function aaveWithdrawAllAndSell(
        address aTokenAddress,
        address depositToken,
        address outputToken,
        IAaveLendingPool aaveLendingPool,
        IUniswapV2Router02 router
    ) public /* onlyManager */ {
        // TODO: reenable permissions; demo purpose only

        uint aTokenBalance = assetBalance(aTokenAddress);
        // withdraw all deposit in aave
        aaveLendingPool.withdraw(depositToken, aTokenBalance, address(this));

        // aTokens are 1:1 with deposited tokens, assume withdrawn amount is 1:1
        address[] memory path = new address[](2);
        path[0] = depositToken;
        path[1] = outputToken;
        IERC20Detailed(path[0]).approve(address(router), aTokenBalance);
        router.swapExactTokensForTokens(aTokenBalance, 0, path, address(this), block.timestamp);
    }
}
