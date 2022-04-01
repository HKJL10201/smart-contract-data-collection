pragma solidity ^0.5.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";

interface Erc20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function allowance(address owner, address spender) external returns (uint256);
    function symbol() external returns (string memory);
}

interface CEth {
    function mint() external payable;
    function balanceOf(address account) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function exchangeRateCurrent() external returns (uint256);
    function supplyRatePerBlock() external returns (uint256);
    function redeem(uint) external returns (uint);
    function redeemUnderlying(uint) external returns (uint);
    function borrow(uint256) external returns (uint256);
    function repayBorrow() external payable;
    function borrowBalanceCurrent(address) external returns (uint256);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

interface CErc20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function mint(uint256) external payable returns (uint256);
    function mintETH(uint256) external payable returns (uint256);
    function redeem(uint) external payable returns  (uint);
    function redeemUnderlying(uint) external payable returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrow(uint borrowAmount) external payable returns (uint);
    function repayBorrow(uint repayAmount) external payable returns (uint);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

interface Comptroller {
    function enterMarkets(address[] calldata)
        external
        returns (uint256[] memory);

    function claimComp(address holder) external;
}

interface IWETH {
  function deposit() external payable;
  function withdraw(uint wad) external;
  function totalSupply() external view returns (uint);
  function approve(address guy, uint wad) external returns (bool);
  function transfer(address dst, uint wad) external returns (bool);
  function transferFrom(address src, address dst, uint wad) external returns (bool);
}

interface IUniPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface BPool {

    function isPublicSwap() external view returns (bool);
    function isFinalized() external view returns (bool);
    function isBound(address t) external view returns (bool);
    function getNumTokens() external view returns (uint);
    function getCurrentTokens() external view returns (address[] memory tokens);
    function getFinalTokens() external view returns (address[] memory tokens);
    function getDenormalizedWeight(address token) external view returns (uint);
    function getTotalDenormalizedWeight() external view returns (uint);
    function getNormalizedWeight(address token) external view returns (uint);
    function getBalance(address token) external view returns (uint);
    function getSwapFee() external view returns (uint);
    function getController() external view returns (address);

    function setSwapFee(uint swapFee) external;
    function setController(address manager) external;
    function setPublicSwap(bool public_) external;
    function finalize() external;
    function bind(address token, uint balance, uint denorm) external;
    function rebind(address token, uint balance, uint denorm) external;
    function unbind(address token) external;
    function gulp(address token) external;

    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint spotPrice);
    function getSpotPriceSansFee(address tokenIn, address tokenOut) external view returns (uint spotPrice);

    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external;   
    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external;

    function swapExactAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    ) external returns (uint tokenAmountOut, uint spotPriceAfter);

    function swapExactAmountOut(
        address tokenIn,
        uint maxAmountIn,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPrice
    ) external returns (uint tokenAmountIn, uint spotPriceAfter);

    function joinswapExternAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        uint minPoolAmountOut
    ) external returns (uint poolAmountOut);

    function joinswapPoolAmountOut(
        address tokenIn,
        uint poolAmountOut,
        uint maxAmountIn
    ) external returns (uint tokenAmountIn);

    function exitswapPoolAmountIn(
        address tokenOut,
        uint poolAmountIn,
        uint minAmountOut
    ) external returns (uint tokenAmountOut);

    function exitswapExternAmountOut(
        address tokenOut,
        uint tokenAmountOut,
        uint maxPoolAmountIn
    ) external returns (uint poolAmountIn);

    function totalSupply() external view returns (uint);
    function balanceOf(address whom) external view returns (uint);
    function allowance(address src, address dst) external view returns (uint);

    function approve(address dst, uint amt) external returns (bool);
    function transfer(address dst, uint amt) external returns (bool);
    function transferFrom(
        address src, address dst, uint amt
    ) external returns (bool);

    function calcSpotPrice(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint swapFee
    ) external pure returns (uint spotPrice);

    function calcOutGivenIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountIn,
        uint swapFee
    ) external pure returns (uint tokenAmountOut);

    function calcInGivenOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountOut,
        uint swapFee
    ) external pure returns (uint tokenAmountIn);

    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    ) external pure returns (uint poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountOut,
        uint swapFee
    ) external pure returns (uint tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountIn,
        uint swapFee
    ) external pure returns (uint tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee
    ) external pure returns (uint poolAmountIn);

}

interface Structs {
    struct Val {
        uint256 value;
    }

    enum ActionType {
      Deposit,   // supply tokens
      Withdraw,  // borrow tokens
      Transfer,  // transfer balance between accounts
      Buy,       // buy an amount of some token (externally)
      Sell,      // sell an amount of some token (externally)
      Trade,     // trade tokens against another account
      Liquidate, // liquidate an undercollateralized or expiring account
      Vaporize,  // use excess tokens to zero-out a completely negative account
      Call       // send arbitrary data to an address
    }

    enum AssetDenomination {
        Wei // the amount is denominated in wei
    }

    enum AssetReference {
        Delta // the amount is given as a delta from the current value
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct Info {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }
}

contract DyDxPool is Structs {
    function getAccountWei(Info memory account, uint256 marketId) public view returns (Wei memory);
    function operate(Info[] memory, ActionArgs[] memory) public;
}

pragma solidity ^0.5.0;


contract DyDxFlashLoan is Structs {
    DyDxPool pool = DyDxPool(0x4EC3570cADaAEE08Ae384779B0f3A45EF85289DE);                       // KOVAN SOLO MARGIN ADDRESS

    address payable public WETH = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;                  // KOVAN WETH ADDRESS
    address payable public SAI = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
    address payable public USDC = 0xe22da380ee6B445bb8273C81944ADEB6E8450422;                   // KOVAN USDC ADDRESS
    address payable public DAI = 0xC4375B7De8af5a38a93548eb8453a498222C4fF2;                    // KOVAN DAI ADDRESS
    mapping(address => uint256) public currencies;

    constructor() public {
        currencies[WETH] = 1;
        currencies[SAI] = 2;
        currencies[USDC] = 3;
        currencies[DAI] = 4;
    }

    modifier onlyPool() {
        require(
            msg.sender == address(pool),
            "FlashLoan: could be called by DyDx pool only"
        );
        _;
    }

    function tokenToMarketId(address token) public view returns (uint256) {
        uint256 marketId = currencies[token];
        require(marketId != 0, "FlashLoan: Unsupported token");
        return marketId - 1;
    }

    // the DyDx will call `callFunction(address sender, Info memory accountInfo, bytes memory data) public` after during `operate` call
    function flashloan(address token, uint256 amount, bytes memory data)
        internal
    {
        IERC20(token).approve(address(pool), amount + 1);
        Info[] memory infos = new Info[](1);
        ActionArgs[] memory args = new ActionArgs[](3);

        infos[0] = Info(address(this), 0);

        AssetAmount memory wamt = AssetAmount(
            false,
            AssetDenomination.Wei,
            AssetReference.Delta,
            amount
        );
        ActionArgs memory withdraw;
        withdraw.actionType = ActionType.Withdraw;
        withdraw.accountId = 0;
        withdraw.amount = wamt;
        withdraw.primaryMarketId = tokenToMarketId(token);
        withdraw.otherAddress = address(this);

        args[0] = withdraw;

        ActionArgs memory call;
        call.actionType = ActionType.Call;
        call.accountId = 0;
        call.otherAddress = address(this);
        call.data = data;

        args[1] = call;

        ActionArgs memory deposit;
        AssetAmount memory damt = AssetAmount(
            true,
            AssetDenomination.Wei,
            AssetReference.Delta,
            amount + 1
        );
        deposit.actionType = ActionType.Deposit;
        deposit.accountId = 0;
        deposit.amount = damt;
        deposit.primaryMarketId = tokenToMarketId(token);
        deposit.otherAddress = address(this);

        args[2] = deposit;

        pool.operate(infos, args);
    }
}

pragma solidity ^0.5.0;


contract compoundFarmer is DyDxFlashLoan  {
    
    using SafeMath for uint256;
    using Math for uint256;
    using SafeERC20 for IERC20;

    /* ========== STRUCT ========== */

    // Info of each user.
    struct UserInfo {
        // How many ETH has provided.
        uint256 investInput;
        // How many eth borrowed from compound
        uint256 borrowAmount;
        // How many ceth the user has accumelated
        uint256 cTokenBalance;
        // How many debt the user has accumelated
        uint256 borrowBalance;

    }

    // Info of each pool.
    struct PoolInfo {
        // Accumulated Share
        uint256 accInvest;
        uint256 accBorrow;
        uint256 totalcToken;
        uint256 totalBorrow;
    }

    // Info of each user that stakes WETH tokens.
    mapping(address => UserInfo) public userInfo;
    
    // farm pool info
    PoolInfo public poolInfo;
    
    address payable wethAddress = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    Erc20 weth = Erc20(wethAddress);

    address payable daiAddress = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
    Erc20 dai = Erc20(daiAddress);

    address payable cDaiAddress = 0xF0d0EB522cfa50B716B3b1604C4F0fA6f04376AD;
    CErc20 cDai = CErc20(cDaiAddress);
    
    address payable cETHAddress = 0x41B5844f4680a8C38fBb695b7F9CFd1F64474a72;
    CEth cEth = CEth(cETHAddress);

    // Kovan Comptroller
    address payable comptrollerAddress = 0x5eAe89DC1C671724A672ff0630122ee834098657;
    Comptroller comptroller = Comptroller(comptrollerAddress);

    // COMP ERC-20 token
    // https://etherscan.io/token/0xc00e94cb662c3520282e6f5717214004a7f26888
    Erc20 compToken = Erc20(0x61460874a7196d6a22D1eE4922473664b3E95270);

    // Deposit/Withdraw values
    bytes32 DEPOSIT = keccak256("DEPOSIT");
    bytes32 WITHDRAW = keccak256("WITHDRAW");

    // Contract owner
    address payable owner;
    
    
    IWETH IWETH_Contract = IWETH(wethAddress); 

    event FlashLoan(address indexed _from, bytes32 indexed _id, uint _value);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner!");
        _;
    }


    constructor() public {
        // Track the contract owner
        owner = msg.sender;

        // Enter the cEth market so you can borrow another type of asset
        address[] memory cTokens = new address[](1);
        cTokens[0] = cETHAddress;
        
        uint256[] memory errors = comptroller.enterMarkets(cTokens);
        if (errors[0] != 0) {
            revert("Comptroller.enterMarkets failed.");
        }
        poolInfo = PoolInfo({
            accInvest : 0,
            accBorrow : 0,
            totalcToken : 0,
            totalBorrow : 0
        });
        
 
    }
    

    function() external payable {}

    // Do not deposit all your ETH because you must pay flash loan fees
    // Always keep at least 0.0001 ETH in the contract
    function depositETH() public payable returns (bool){
        
        // Total deposit: 35% initial amount, 65% flash loan
        uint256 totalAmount = (msg.value * 100) / 35;
        
        address payable investor = msg.sender;
        uint256 investAmount = msg.value;

        // Wrap the ETH we got from the msg.sender
        Wrap(msg.value); 

        // intitalize struct to user 
        UserInfo storage user = userInfo[investor];

        // if user deposits more then 0 add deposited amount to struct
        if (msg.value > 0) {
            user.investInput = user.investInput.add(investAmount);
            poolInfo.accInvest = poolInfo.accInvest.add(investAmount);             
        }
        
        // loan is 60% of total deposit
        uint256 flashLoanAmount = totalAmount - investAmount;

        // Get WETH Flash Loan for "DEPOSIT"
        bytes memory data = abi.encode(totalAmount, flashLoanAmount, DEPOSIT, investor);
        flashloan(wethAddress, flashLoanAmount, data); // execution goes to `callFunction`

        // Handle remaining execution inside handleDeposit() function

        return true;
    }

    function withdrawEth() external returns (bool){
        
        address payable investor = msg.sender;
        updateUserBalance(investor);

        UserInfo storage user = userInfo[investor];
        
        // Total deposit: 35% initial amount, 65% flash loan
        uint256 totalAmount = (user.borrowBalance * 100) / 35;

        // loan is 65% of total deposit
        uint256 flashLoanAmount = user.borrowBalance;

        // Use flash loan to payback borrowed amount
        bytes memory data = abi.encode(totalAmount, flashLoanAmount,WITHDRAW, investor);
        flashloan(wethAddress, flashLoanAmount, data); // execution goes to `callFunction`


        // Handle repayment inside handleWithdraw() function
        

        // Claim COMP tokens
        comptroller.claimComp(address(this));

        // Withdraw COMP tokens
        compToken.transfer(owner, compToken.balanceOf(address(this)));

        // Calculate how much WETH we got left after repaying the loan 
        uint256 balanceWeth = Erc20(wethAddress).balanceOf(address(this));
        // unwrap it
        Unwrap(balanceWeth);
        uint256 accumelatedInvest = poolInfo.accInvest;
        // reset accInvest 
        poolInfo.accInvest = accumelatedInvest.sub(user.investInput);

        // Send it to investor 
        withdrawETH();
        user.investInput = 0; 

        return true;
    }

    // 3. Withdraw ETH - input tokenAddress
    function withdrawETH() internal {
        // 3.1 withdraw ALL ETH to msg.sender
        msg.sender.transfer(address(this).balance);
        
    }
    
    // 4. Wrap ETH - amount input variable
    function Wrap (uint256 amount) internal  {

        //  4.1 send ETH to WETH mycontract 
        WETH.call.gas(200000).value(amount)("");
        
        //  4.2 approve mycontract to control WETH balance 
        IWETH_Contract.approve(address(this), amount);
        
        //  4.4 transfer WETH to mycontract 
        IWETH_Contract.transfer(address(this), amount);
    }
    
    // 5. Unwrap WETH - amount input variable
    function Unwrap (uint256 amount) internal {
        
        //  5.2 approve mycontract to control the amount 
        IWETH_Contract.approve(address(this), amount);
        
        //  5.3 Withdraw ETH tokens from WETH contract 
        IWETH_Contract.withdraw(amount);
    }

    function callFunction(
        address, /* sender */
        Info calldata, /* accountInfo */
        bytes calldata data
    ) external onlyPool {
        (uint256 totalAmount, uint256 flashLoanAmount, bytes32 operation, address investor) = abi
            .decode(data, (uint256, uint256, bytes32, address));
            
        if(operation == DEPOSIT) {
            handleDeposit(totalAmount, flashLoanAmount, investor);
        }
        
        if(operation == WITHDRAW) {
            handleWithdraw(totalAmount, flashLoanAmount,investor);
        }
     
    }

    function handleDeposit(uint256 totalAmount, uint256 flashLoanAmount, address investor) internal returns (bool) {
        UserInfo storage user = userInfo[investor];
        
        uint256 balanceWeth = Erc20(wethAddress).balanceOf(address(this));
        // Unwrap everything
        Unwrap(balanceWeth);
        
        uint256 ethBalance = address(this).balance; 

        // Provide all ETH as collateral by minting cEth tokens
        cEth.mint.value(ethBalance).gas(250000)();
       
        // Borrow just enough ETH to pay the loan back 
        cEth.borrow(flashLoanAmount+1);
        user.borrowAmount = flashLoanAmount +1; 

        // Wrap the borrowed amount so we can pay it back 
        Wrap(flashLoanAmount+1);

        // update the pool info - borrowamount and current ctoken amount 
        UpdatePool();
        updateUserBalance(investor);
        // Start earning COMP tokens, yay!
        return true;
        
    }
    

    function handleWithdraw(uint256 totalAmount, uint256 flashLoanAmount, address investor) internal returns (bool) {
        UserInfo storage user = userInfo[investor];

        uint256 balanceWeth = Erc20(wethAddress).balanceOf(address(this));
        // Unwrap everything
        Unwrap(balanceWeth);

        // repay borrow 
        cEth.repayBorrow.value(user.borrowBalance)();
        user.borrowAmount = 0; 

        // Redeem cEth
        cEth.redeem(user.cTokenBalance);
        user.cTokenBalance = 0; 

        uint256 ethBalance = address(this).balance;
        // wrap it so we can repay the loan 
        Wrap(ethBalance);

        UpdatePool();
        updateUserBalance(investor);

        return true;
    }


    // Fallback in case any other tokens are sent to this contract
    function withdrawToken(address _tokenAddress) public onlyOwner {
        uint256 balance = Erc20(_tokenAddress).balanceOf(address(this));
        Erc20(_tokenAddress).transfer(owner, balance);
    }


    function UpdatePool() internal {
        // Get curent borrow Balance
        uint256 balanceBorrow = cEth.borrowBalanceCurrent(address(this));
        poolInfo.totalBorrow = balanceBorrow;

        // get the amount of cEth the contract has accumelated
        uint256 balanceCEth = cEth.balanceOf(address(this));
        poolInfo.totalcToken = balanceCEth;

    }

    function updateUserBalance(address user) internal {
        // Get curent borrow Balance
        uint256 balanceBorrow = cEth.borrowBalanceCurrent(address(this));
        poolInfo.accBorrow = balanceBorrow;

        // get the amount of cEth the contract has accumelated
        uint256 balanceCEth = cEth.balanceOf(address(this));
        poolInfo.totalcToken = balanceCEth;

        UserInfo storage user = userInfo[user];
        uint256 share = (user.investInput/poolInfo.accInvest)*100;

        uint256 userBorrowBal = (balanceBorrow*share)/100;
        user.borrowBalance = userBorrowBal;

        uint256 usercTokenBal = (balanceCEth*share)/100;
        user.cTokenBalance = usercTokenBal;
    }
}
