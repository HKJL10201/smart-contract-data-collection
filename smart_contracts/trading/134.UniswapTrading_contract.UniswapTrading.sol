//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * SAFEMATH LIBRARY
 */
library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address token0, address token1) external returns (address);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function getAmountsOut(
        uint256 amountIn, 
        address[] memory path
    )external view returns (uint256[] memory amounts);
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

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external; 
}

interface IDEXPair {
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

contract UniswapTrading {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    //real net WETH address
    // address private constant WETH = 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2;
    
    address private constant uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant uniswapFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    //ropsten testnet WETH addr
    address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    //ropsten testnet USDT addr
    address private constant USDT = 0x110a13FC3efE6A245B50102D2d79B3E76125Ae83;
    IDEXRouter router= IDEXRouter(uniswapRouter);
    

    function getAllowance(
        address token, 
        address owner, 
        address spender
    ) public view returns (uint256)
    {
        IERC20 _token;
        _token= IERC20(token);
        uint256 allowances= _token.allowance(owner, spender);
        return allowances;
    }

    //Function to get pair address if it exists.
    function getPairAddress(
        address tokenA,
        address tokenB
    ) external returns (address)
    {
        IDEXFactory factory= IDEXFactory(uniswapFactory);
        address pairAddress;
        pairAddress= factory.getPair(tokenA, tokenB);
        return pairAddress;
    }

    //Function to get token0 address from pair.
    function getToken0(
        address pairAddress
    ) public view returns (address)
    {
        IDEXPair pair= IDEXPair(pairAddress);
        address tokenIn= pair.token0();
        return tokenIn;
    }

    //Fnction to get token1 address from pair.
    function getToken1(
        address pairAddress
    ) public view returns (address)
    {
        IDEXPair pair= IDEXPair(pairAddress);
        address tokenOut= pair.token1();
        return tokenOut;
    }

    function doApprove(
        address token,
        address spender,
        uint256 amount
    ) internal returns (bool)
    {
        IERC20 _token;
        _token= IERC20(token);
        _token.approve(spender, amount);
        return true;
    }

    function doSafeApprove(
        // require(msg.sender == address(this), "Ok good msg.sender is the owner");
        address token,
        address spender,
        uint256 amount
    ) internal returns (bool)
    {
        IERC20 _token;
        _token= IERC20(token);
        uint256 allownaces= getAllowance(token, address(this), spender);
        if(allownaces != 0){
            _token.safeDecreaseAllowance(spender, allownaces);
            _token.safeApprove(spender, amount);
        }
        else{
            _token.safeApprove(spender, amount);
        }
        return true;
    }

    // This function will return the minimum amount from a swap.
    // Input the 3 parameters below and it will return the minimum amount out.
    function getAmountOutMin(
        address _tokenIn, 
        address _tokenOut, 
        uint256 _amountIn
    ) public view returns (uint256)
    {
        //path is array of addresses.
        // This path array will have 3 addresses [tokenIn, WRAPPED, tokenOut].
        // The if statement below takes into account if token in or token out is WRAPPED,  then the path has only 2 addresses.
        address[] memory path;
        if(_tokenIn == WETH || _tokenOut == WETH){
            path= new address[](2);
            path[0]= _tokenIn;
            path[1]= _tokenOut;
        }else{
            path= new address[](3);
            path[0]= _tokenIn;
            path[1]= WETH;
            path[2]= _tokenOut;
        }
        uint256[] memory amountOutMins= router.getAmountsOut(_amountIn, path);
        uint256 amountOut= amountOutMins[path.length -1];
        return amountOut;
    }

    function swapWithETH(
        address tokenInput, 
        address tokenOut, 
        bool buyToken1
    ) public payable returns (bool) 
    {
        require(buyToken1 == true, "Not set as buy");
        require(tokenOut != WETH, "Directly deposit to WETH");
        address[] memory path;
        path = new address[](2);
        path[0] = tokenInput;
        path[1] = tokenOut;
        router.swapExactETHForTokens{value: msg.value}(0, path, msg.sender, block.timestamp);
        return true;
    }

    function swapTokensForTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address to,
        bool buyToken1
    ) public returns (bool) {
        require(buyToken1 == true, "Not set as buy");
        require(_tokenIn != _tokenOut, "The same token on both sides of the swap");
        // First we need to transfer the amount in tokens from the msg.sender to this contract.
        // This contract will then have the amount of in tokens to be traded.
        uint256 allowances;
        allowances= getAllowance(_tokenIn, msg.sender, address(this));
        require(allowances >= amountIn, "You need to approve about the token contract firstly.");
        
        IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        // Next we need to allow the Uniswap router to spend the token we just sent to this contract.
        // By calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract.
        bool approveStatus;
        if(_tokenIn == USDT){
            
            approveStatus= doSafeApprove(_tokenIn, uniswapRouter, amountIn);
        }else{
            approveStatus= doApprove(_tokenIn, uniswapRouter, amountIn);
        }
        
        require(approveStatus == true, "Error occured during the approval");
        address[] memory path;
        if(_tokenIn == WETH || _tokenOut == WETH){
            path= new address[](2);
            path[0]= _tokenIn;
            path[1]= _tokenOut;
        } else{
            path= new address[](3);
            path[0]= _tokenIn;
            path[1]= WETH;
            path[2]= _tokenOut;
        }
        router.swapExactTokensForTokens(amountIn, amountOutMin, path, to, block.timestamp);
        return true;

    }
    function doSwap(
        address poolAddress,
        bool buyToken0,
        // uint256 sqrtPriceLimitX96,
        // uint256 price0Usd,
        // uint256 price1Usd,
        // uint256 ethPriceUsd,
        // uint256 minPrUsd,
        // uint256 minPrRel,
        // uint blockHeightRequired,
        // uint256 minerReward,
        uint256 maxAmountIn
    ) public returns(bool) {
        address to = msg.sender;
        address tokenIn= getToken0(poolAddress);
        address tokenOut= getToken1(poolAddress);
        bool swapStatus;
        swapStatus= swapTokensForTokens(
            tokenIn,
            tokenOut,
            maxAmountIn,
            0,
            to,
            buyToken0
        );
        require(swapStatus == true, "SwapExactTokensForTokens Failed");
        return true;
    }
}
