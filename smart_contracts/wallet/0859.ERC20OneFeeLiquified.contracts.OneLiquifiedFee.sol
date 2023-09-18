pragma solidity 0.8.19;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}


contract OneLiquifiedFee is ERC20, Ownable {
    IUniswapV2Router02 public uniswapV2Router;
    bool public marketActive = true;
    address public uniswapV2Pair;
    address public feeWallet;

    uint public buyFee = 5;
    uint public sellFee = 10;

    uint256 public tSupply;

    uint256 public minTokenBefSwap = 20_000 * 10 ** decimals();
    uint256 public tokToSwap = 20_000 * 10 ** decimals();
    uint256 public intervalSecondForSwap = 60;
    uint256 public lastSwapAt;

    mapping(address => bool) public excludedFromFees;
    mapping(address => bool) public premarketUser;
    mapping(address => bool) public automatedMarketMakerPairs;

    event FeeCollected(uint256 indexed collectedAmount);
    event retrievedToken(address indexed retrievedToken, uint256 indexed retrievedAmount);
    event coinRetrived(uint256 indexed coinAmount);
    event buyFeeUpdated(uint256 indexed newBuyFee);
    event sellFeeUpdated(uint256 indexed newSellFee);
    constructor(address _routerAddress, address _feeReceiver) ERC20 ('OneLiquifiedFee', 'OLF') {
        tSupply = 10_000_000_000 * 10 ** decimals();
        uniswapV2Router = IUniswapV2Router02(_routerAddress);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        feeWallet = _feeReceiver;

        excludedFromFees[feeWallet] = true;
        excludedFromFees[address(this)] = true;
        excludedFromFees[owner()] = true;

        premarketUser[owner()] = true;

        automatedMarketMakerPairs[uniswapV2Pair] = true;
        super._mint(msg.sender, tSupply);
    }

    receive() external payable {}

    function _transfer(address from, address to, uint256 amount) internal override {        
        if(!marketActive){
            require(premarketUser[from], "Trades currently unavailable");
        }
        
        bool isBuy = false;
        bool isPayingFee = true;
        bool shouldSwap = balanceOf(address(this)) > minTokenBefSwap;
        if(automatedMarketMakerPairs[from]) { //buy
            isBuy = true;
            if(excludedFromFees[to]){
                isPayingFee = false;
            }
        } else if(automatedMarketMakerPairs[to]) { //sell
                if(excludedFromFees[from]){
                    isPayingFee = false;
                } 
        }        

        if(isPayingFee){
            if(isBuy) {
                uint256 feeAmount = (amount * buyFee) / 100;
                amount -= feeAmount;
                super._transfer(from, address(this), feeAmount);
            } else {
                uint256 feeAmount = (amount * sellFee) / 100;
                amount -= feeAmount;
                super._transfer(from, address(this), feeAmount);
                if (shouldSwap) {
                    bool hasPassedTime = (block.timestamp + intervalSecondForSwap) > lastSwapAt;
                    if(hasPassedTime){
                        lastSwapAt = block.timestamp;
                        swapAndLiquify();
                    }            
                }
            }
        }
        super._transfer(from, to, amount);
    }

    function swapAndLiquify() internal {        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokToSwap);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens
            (tokToSwap, 0, path, address(this), block.timestamp);
        distributeLiquifiedToken();        
    }

    function distributeLiquifiedToken() internal {
        uint256 contractBalance = address(this).balance;
        (bool success,) = payable(feeWallet).call{value: contractBalance}("");
        if(success){
            emit FeeCollected(contractBalance);
        }
    }

    //better safe then sorry
        function retrieveForeignTokens(address tokenToRetrieve) external onlyOwner returns(bool sent){
        IERC20 token = IERC20(tokenToRetrieve);
        uint256 amount = token.balanceOf(address(this));
        sent = token.transfer(owner(), amount);
        emit retrievedToken(tokenToRetrieve, amount);
    }

    function retrieveCoin() external onlyOwner returns(bool sent){
        uint256 balance = address(this).balance;
        (bool success, ) = payable(owner()).call{value: balance}("");
        sent = success;
        emit coinRetrived(balance);
    }

    //set
    function setBuyFee(uint256 _newBuyFee) external onlyOwner{
        require(_newBuyFee < 25, "Fee too high");
        buyFee = _newBuyFee;
        emit buyFeeUpdated(_newBuyFee);
    }

    function setSellFee(uint256 _newSellFee) external onlyOwner{
        require(_newSellFee < 25, "Fee too high");
        sellFee = _newSellFee;
        emit sellFeeUpdated(_newSellFee);
    }

}