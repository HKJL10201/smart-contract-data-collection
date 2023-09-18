// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
    // This will hold the address of BDT and will be initialized once the contract is deployed.
    address public binnaDevTokenAddress;

    // Exchange is inheriting ERC20, because our exchange would
    // keep track of Binna Dev LP tokens
    constructor(address _BinnaDevToken) ERC20("BinnaDev LP Token", "BDT_LP") {
        // checks if the address is a null address
        require(
            _BinnaDevToken != address(0),
            "Token address passed is a null address"
        );
        binnaDevTokenAddress = _BinnaDevToken;
    }

    /**
     * @dev Returns the amount of `Binna Dev Tokens` held by the contract
     */
    function getReserve() public view returns (uint) {
        return ERC20(binnaDevTokenAddress).balanceOf(address(this));
    }

    /**
     * @dev Adds liquidity to the exchange.
     */
    function addLiquidity(uint _amount) public payable returns (uint) {
        uint liquidity;
        uint ethBalance = address(this).balance;
        uint binnaDevTokenReserve = getReserve();
        ERC20 binnaDevToken = ERC20(binnaDevTokenAddress);

        if (binnaDevTokenReserve == 0) {
            binnaDevToken.transferFrom(msg.sender, address(this), _amount);
            liquidity = ethBalance;
            _mint(msg.sender, liquidity);
        } else {
            uint ethReserve = ethBalance - msg.value;
            uint binnaDevTokenAmount = (msg.value * binnaDevTokenReserve) /
                (ethReserve);

            require(
                _amount >= binnaDevTokenAmount,
                "Amount of tokens sent is less than the minimum tokens required"
            );
            binnaDevToken.transferFrom(
                msg.sender,
                address(this),
                binnaDevTokenAmount
            );
            liquidity = (totalSupply() * msg.value) / ethReserve;
            _mint(msg.sender, liquidity);
        }
        return liquidity;
    }

    /**
     * @dev Returns the amount Eth/Binna Dev tokens that would be returned to the user
     * in the swap
     */
    function removeLiquidity(uint _amount) public returns (uint, uint) {
        require(_amount > 0, "_amount should be greater than zero");
        uint ethReserve = address(this).balance;
        uint _totalSupply = totalSupply();

        uint ethAmount = (ethReserve * _amount) / _totalSupply;
        uint binnaDevTokenAmount = (getReserve() * _amount) / _totalSupply;
        _burn(msg.sender, _amount);

        payable(msg.sender).transfer(ethAmount);
        ERC20(binnaDevTokenAddress).transfer(msg.sender, binnaDevTokenAmount);

        return (ethAmount, binnaDevTokenAmount);
    }

    /**
     * @dev Returns the amount Eth/Binna Dev tokens that would be returned to the user
     * in the swap
     */
    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
        uint256 inputAmountWithFee = inputAmount * 99;

        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;
        return numerator / denominator;
    }

    /**
     * @dev Swaps Eth for BinnaDev Tokens
     */
    function ethToBinnaDevToken(uint _minTokens) public payable {
        uint256 tokenReserve = getReserve();
        uint256 tokensBought = getAmountOfTokens(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );

        require(tokensBought >= _minTokens, "insufficient output amount");
        ERC20(binnaDevTokenAddress).transfer(msg.sender, tokensBought);
    }

    /**
     * @dev Swaps BinnaDev Tokens for Eth
     */
    function binnaDevTokenToEth(uint _tokensSold, uint _minEth) public {
        uint256 tokenReserve = getReserve();
        // call the `getAmountOfTokens` to get the amount of Eth
        // that would be returned to the user after the swap
        uint256 ethBought = getAmountOfTokens(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );

        require(ethBought >= _minEth, "insufficient output amount");
        ERC20(binnaDevTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokensSold
        );
        payable(msg.sender).transfer(ethBought);
    }
}
