pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";


contract exchange is ERC20{
    ERC20 public cryptoDevTokenAddress;

    constructor(address _cryptoDevTokenAddress) ERC20("Crypto dev LP","LPT") {
        require(_cryptoDevTokenAddress!=address(0),"Invalid Address");
        cryptoDevTokenAddress = ERC20(_cryptoDevTokenAddress);
    }

    function getReserve1() public view returns(uint) {
        return cryptoDevTokenAddress.balanceOf(address(this));
    }
    
    function getReserve2() public view returns(uint) {
        return address(this).balance;
    }

   function addLiquidity(uint256 amountOfToken) public payable returns (uint256) {

        uint256 lpTokensToMint;
        uint256 ethReserveBalance = address(this).balance;
        uint256 tokenReserveBalance = getReserve1();
    
        // If the reserve is empty, take any user supplied value for initial liquidity
        if (tokenReserveBalance == 0) {
            // Transfer the token from the user to the exchange
            cryptoDevTokenAddress.transferFrom(msg.sender, address(this), amountOfToken);

            // lpTokensToMint = ethReserveBalance = msg.value
            lpTokensToMint = ethReserveBalance;

            // Mint LP tokens to the user
            _mint(msg.sender, lpTokensToMint);

            return lpTokensToMint;
        }

        // If the reserve is not empty, calculate the amount of LP Tokens to be minted
        uint256 ethReservePriorToFunctionCall = ethReserveBalance - msg.value;
        uint256 minTokenAmountRequired = (msg.value * tokenReserveBalance) /
            ethReservePriorToFunctionCall;

        require(
            amountOfToken >= minTokenAmountRequired,
            "Insufficient amount of tokens provided"
        );

        // Transfer the token from the user to the exchange
        cryptoDevTokenAddress.transferFrom(msg.sender, address(this), minTokenAmountRequired);

        // Calculate the amount of LP tokens to be minted
        lpTokensToMint =
            (totalSupply() * msg.value) /
            ethReservePriorToFunctionCall;

        // Mint LP tokens to the user
        _mint(msg.sender, lpTokensToMint);

        return lpTokensToMint;
    }

  
  
    function removeLiquidity( uint256 amountOfLPTokens) public returns (uint256, uint256) {
        // Check that the user wants to remove >0 LP tokens
        require(
            amountOfLPTokens > 0,
            "Amount of tokens to remove must be greater than 0"
        );

        uint256 ethReserveBalance =getReserve2();
        uint256 lpTokenTotalSupply = totalSupply();

        // Calculate the amount of ETH and tokens to return to the user
        uint256 ethToReturn = (ethReserveBalance * amountOfLPTokens) /
            lpTokenTotalSupply;
            
        uint256 tokenToReturn = (getReserve1() * amountOfLPTokens) /
            lpTokenTotalSupply;

        // Burn the LP tokens from the user, and transfer the ETH and tokens to the user
        _burn(msg.sender, amountOfLPTokens);
        payable(msg.sender).transfer(ethToReturn);
        cryptoDevTokenAddress.transfer(msg.sender, tokenToReturn);

        return (ethToReturn, tokenToReturn);
    }

    function getOutputAmountFromSwap(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(
            inputReserve > 0 && outputReserve > 0,
            "Reserves must be greater than 0"
        );

        uint256 inputAmountWithFee = inputAmount * 99;

        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        return numerator / denominator;
    }

    // ethToTokenSwap allows users to swap ETH for tokens
    function ethToTokenSwap(uint256 minTokensToReceive) public payable {
        uint256 tokenReserveBalance = getReserve1();
        uint256 tokensToReceive = getOutputAmountFromSwap(
            msg.value,
            getReserve2() - msg.value,
            tokenReserveBalance
        );

        require(
            tokensToReceive >= minTokensToReceive,
            "Tokens received are less than minimum tokens expected"
        );

        cryptoDevTokenAddress.transfer(msg.sender, tokensToReceive);
    }

    // tokenToEthSwap allows users to swap tokens for ETH
    function tokenToEthSwap( uint256 tokensToSwap, uint256 minEthToReceive) public {
        uint256 tokenReserveBalance = getReserve1();
        uint256 ethToReceive = getOutputAmountFromSwap(
            tokensToSwap,
            tokenReserveBalance,
            address(this).balance
        );

        require(
            ethToReceive >= minEthToReceive,
            "ETH received is less than minimum ETH expected"
        );

        cryptoDevTokenAddress.transferFrom(
            msg.sender,
            address(this),
            tokensToSwap
        );

        payable(msg.sender).transfer(ethToReceive);
    }
   

    receive() external payable{}
    fallback() external payable{}

}