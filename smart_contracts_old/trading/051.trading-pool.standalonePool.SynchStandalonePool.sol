// Synch finance team
pragma solidity ^0.6.12;

contract Owned {
    address public owner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, 'Synch: you are not the owner');
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        address old = owner;
        owner = _newOwner;
        emit OwnershipTransferred(old, _newOwner);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "Synch ERC20: transfer from the zero address");
        require(recipient != address(0), "Synch ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Synch ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Synch ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "Synch ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "Synch ERC20: approve from the zero address");
        require(spender != address(0), "Synch ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract SynchStandalonePool is ERC20("Synch Trading Pool", "STP"), Owned {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public base; // default as USDC
    IERC20 public synch;

    uint public sharePrice;
    uint public allocPrice; // determine how many synch stake required for each base token

    bool public allowDeposit;
    bool public allowWithdraw;

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IUniswapV2Router02 public uniswapRouter;

    event UpdateSharePrice(uint previous, uint current);
    event UpdateAllocPrice(uint previous, uint current);

    event UpdateDepositStatus(bool current);
    event UpdateWithdrawStatus(bool current);

    event UpdateBaseToken(address oldToken, address newToken);
    event TradeToken(address fromToken, address toToken);

    constructor () public {
        uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        base = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        synch = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        allowDeposit = true;
        allowWithdraw = true;
        sharePrice = 10**18;
        allocPrice = 5 * 10**16; // 1 base for 0.05 synch
    }

    receive () payable external {}

    function approveUniRouter (address token, uint256 _amount) internal {
        IERC20(token).safeApprove(address(uniswapRouter), _amount);
    }

    function tradeTokens(address[] memory path, uint amountIn, uint minOut) external onlyOwner returns (uint[] memory) {
        require(!allowDeposit, 'Synch: trade when deposit is locked');
        require(amountIn > 0, "Synch: amountIn is 0");
        require(minOut > 0, "Synch: minOut is 0");

        approveUniRouter(path[0], amountIn);
        uint deadline = block.timestamp;
        return uniswapRouter.swapExactTokensForTokens(amountIn, minOut, path, address(this), deadline);
    }

    function tradeWithETH(address toToken, uint amountIn, uint minOut) external onlyOwner returns (uint[] memory) {
        require(!allowDeposit, 'Synch: trade when deposit is locked');
        require(amountIn > 0, "Synch: amountIn is 0");
        require(minOut > 0, "Synch: minOut is 0");

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = toToken;
        uint deadline = block.timestamp;
        return uniswapRouter.swapETHForExactTokens{ value: amountIn }(minOut, path, address(this), deadline);
    }

    function tradeForETH(address fromToken, uint amountIn, uint minOut) external onlyOwner returns (uint[] memory) {
        require(!allowDeposit, 'Synch: trade when deposit is locked');
        require(amountIn > 0, "Synch: amountIn is 0");
        require(minOut > 0, "Synch: minOut is 0");

        address[] memory path = new address[](2);
        path[0] = fromToken;
        path[1] = WETH;

        approveUniRouter(fromToken, amountIn);
        uint deadline = block.timestamp;
        return uniswapRouter.swapExactTokensForETH(amountIn, minOut, path, address(this), deadline);
    }

    // need to approve both base and synch first
    function deposit(uint _amount) external {
        require(allowDeposit, "Synch: deposit is not available");
        require(_amount > 0, "Synch: deposit is 0");

        synch.safeTransferFrom(_msgSender(), address(this), _amount.mul(allocPrice).div(10**18));
        base.safeTransferFrom(_msgSender(), address(this), _amount);
        uint _share = _amount.mul(10**18).div(sharePrice);
        _mint(_msgSender(), _share);
    }

    /**
     * if no tokens specified, only eth will get withdrew if any, not even synch
     * and your non-specified tokens will automatically transfer to all the other pool members
     * therefore if you call this method manually, please use it with caution
     * if any airdrop rewards occur, this method will withdraw the rewards as well
    */
    function withdraw(uint _share, address[] memory tokens) external {
        require(allowWithdraw, "Synch: withdraw has locked");
        require(_share > 0, "Synch: withdraw greater than 0");
        require(balanceOf(_msgSender()) <= _share, "Synch: withdraw more than you have");
        uint percent = sharePercent(_share);
        _burn(_msgSender(), _share);

        if (address(this).balance > 0) {
            _msgSender().transfer(address(this).balance.mul(percent).div(10**18));
        }

        for (uint i = 0; i < tokens.length; i ++) {
            IERC20 token = IERC20(tokens[i]);
            uint tokenBalance = token.balanceOf(address(this));
            if (tokenBalance > 0) {
                token.safeTransfer(_msgSender(), tokenBalance.mul(percent).div(10**18));
            }
        }
    }

    function stakedAmount() public view returns (uint) {
        return balanceOf(_msgSender()).mul(allocPrice).div(10**18);
    }

    function stakeRewards() external view returns (uint) {
        return sharePercent(balanceOf(_msgSender())).mul(synch.balanceOf(address(this))).div(10**18).sub(stakedAmount());
    }

    function shareToEntryValue(uint _share) external view returns (uint) {
        return _share.mul(sharePrice).div(10**18);
    }

    function sharePercent(uint _share) public view returns (uint) {
        return _share.mul(10**18).div(totalSupply());
    }

    function updateBaseToken(address newBaseToken) external onlyOwner {
        require(!allowDeposit, 'Synch: Only update baseToken when deposit is locked');
        address old = address(base);
        base = IERC20(newBaseToken);
        emit UpdateBaseToken(old, newBaseToken);
    }

    function updateSharePrice(uint _newPrice) external onlyOwner {
        require(!allowDeposit, 'Synch: Only change price when deposit is locked');
        uint oldPrice = sharePrice;
        sharePrice = _newPrice;
        emit UpdateSharePrice(oldPrice, _newPrice);
    }

    function updateAllocPrice(uint _price) external onlyOwner {
        require(!allowDeposit, 'Synch: Only update alloc price when deposit is locked');
        uint old = allocPrice;
        allocPrice = _price;
        emit UpdateAllocPrice(old, allocPrice);
    }

    function toggleAllowDepositStatus() external onlyOwner {
        allowDeposit = !allowDeposit;
        emit UpdateDepositStatus(allowDeposit);
    }

    function toggleAllowWithdrawStatus() external onlyOwner {
        allowWithdraw = !allowWithdraw;
        emit UpdateWithdrawStatus(allowWithdraw);
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Synch Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{ value: amount} ("");
        require(success, "Synch: Address: unable to send value, recipient may have reverted");
    }
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
            "Synch: SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "Synch: SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "Synch: SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "Synch: SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "Synch: SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Synch: SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "Synch: SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "Synch: SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "Synch: SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "Synch: SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IUniswapV2Router01 {
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
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
