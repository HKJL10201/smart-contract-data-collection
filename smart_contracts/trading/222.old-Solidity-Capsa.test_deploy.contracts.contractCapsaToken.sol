// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./capsaToken.sol";

/**
 * This smart contrat swaps CAPSA for USDC.
 * CAPSA is a token emmited by capsa, an open crypto fund accessible to everyone.
 * The CAPSA value is backed by capsa's capital. capsa servers will periodically update
 * the "capital" variable of this smart contract.
 * 
 * A 20% fees on profits is taken every week. This fee will be sent from the fundWallet to the feeWallet.
 * 
 * The capital is denominated in USDC.
 * The supply is the amount of CAPSA issued.
 * The price of the token is defined as following:
 * price(CAPSA/USDC) = capital / supply
 * Price has 6 decimals. It means a price of 1500000 => 1.5 CAPSA = 1 USDC.
 * 
 * - For USDC -> CAPSA swaps, the sent USDC will be sent to the fund wallet, and
 * new CAPSA tokens will be minted on the sender's address.
 * - For CAPSA -> USDC swaps, the sent CAPSA will be burnt, and USDC will be sent to the sender's
 * address from the fundWallet.
 * 
 * At least 5% of the fund's capital will be kept on the fundWallet to provide an exit liquidity.
 */
contract CapsaSwap is Pausable, ReentrancyGuard {

    // Address of the USDC token contract
    address USDCAddress = address(0x0);
    // Address of the CAPSA token contract
    address CAPSAAddress = address(0x0);
    // Address of the fund wallet, on which users will deposit and withdraw USDC
    address fundWallet = address(0x0);
    // Address of the fee wallet, on which to send the weekly 20% commission
    address feeWallet = address(0x0);

    address owner = address(0x0);

    // Capital of capsa in USDC, will be updated from outside
    uint capital = 0;

    // The price have a 10^6 precision. Example: price=1500000 => 1 CAPSA = 1.5 USDC
    uint priceDecimals = 6;
    // Initial price. At the begining 1 CAPSA = 1 USDC.
    uint initalPrice = 1 * 10 ** priceDecimals;

    // Fee in percentage
    uint fee = 20;
    // Fee period
    uint feePeriod = 7 days;

    // Last timestamp at which the fee has been taken
    uint lastTimeFee = 0;
    // Last price at which the fee has been taken
    uint lastPriceFee = 0;
    // Last capital when the fee was taken
    uint lastCapitalFee = 0;

    // Event triggered in the case when the fund wallet has not enough USDC to get the fee
    event NoLiquidityForFee();

    /**
     * Constructor of the CAPSA swap.
     * - _USDCAddress: address of the USDC contract
     * - _CAPSAAddress: address of the CAPSA token contract
     * - _fundWallet: address of the fund wallet
     * - _feeWallet: address of the fee wallet
     */
    constructor(address _USDCAddress, address _CAPSAAddress, address _fundWallet, address _feeWallet) {
        require(_USDCAddress != address(0x0), "USDC contract address cannot be 0x0.");
        require(_CAPSAAddress != address(0x0), "CAPSA contract address cannot be 0x0.");
        require(_fundWallet != address(0x0), "Fund wallet address cannot be 0x0.");
        require(_feeWallet != address(0x0), "Fee wallet address cannot be 0x0.");
        require(_feeWallet != _fundWallet, "Fee wallet cannot be the same as the fund wallet.");
        USDCAddress = _USDCAddress;
        CAPSAAddress = _CAPSAAddress;
        fundWallet = _fundWallet;
        feeWallet = _feeWallet;
        owner = msg.sender;
        lastTimeFee = block.timestamp;
    }

    /**
     * Check that the function is called by the owner of the smart contract.
     */
    modifier ownerCheck() {
        require(msg.sender == owner, "Only owner of this contract can execute this function.");
        _;
    }

    /**
     * Pause the smart contract.
     */
    function pause() external ownerCheck {
        super._pause();
    }

    /**
     * Unpause the smart contract.
     */
    function unpause() external ownerCheck {
        super._unpause();
    }

    /**
     * Set the capital of the fund, aka all the belongings of the fund settled in USDC.
     * This function should be called periodically from capsa's servers.
     * If we haven't took the fee for more than the defined period, we trigger takeFee.
     * 
     * - newCapital: the capital, aka the value of all the belongings of the fund, in USDC (6 decimals)
     */
    function setCapital(uint newCapital) external ownerCheck whenNotPaused {
        capital = newCapital;
        if (lastCapitalFee == 0)
            lastCapitalFee = newCapital;
        if (lastPriceFee == 0)
            lastPriceFee = getPrice();
        if (block.timestamp - lastTimeFee >= feePeriod)
            takeFee();
    }
    
    /**
     * Calculate and take the fee.
     * The fee is calculated as following:
     * weekly_fee = (current_price - price_beginning_of_the_week) * capital_beginning_of_the_week * 2%
     */
    function takeFee() private {
        IERC20 USDC = IERC20(USDCAddress);
        uint price = getPrice();
        int priceDelta = int(price) - int(lastPriceFee);
        if (priceDelta > 0) {
            uint profit = (uint(priceDelta) * lastCapitalFee) / 10 ** 6;
            uint commission = profit * fee / 100;
            if (USDC.balanceOf(fundWallet) >= commission && USDC.allowance(fundWallet, address(this)) >= commission) {
                USDC.transferFrom(fundWallet, feeWallet, commission);
                lastPriceFee = price;
                lastCapitalFee = capital;
                lastTimeFee = block.timestamp;
            } else {
                emit NoLiquidityForFee();
            }
        } else {
            lastPriceFee = price;
            lastCapitalFee = capital;
            lastTimeFee = block.timestamp;
        }
    }
    
    /**
     * Get the price of CAPSA in USDC.
     * 
     * We get this price with the following formula:
     * price(CAPSA/USDC) = capital / supply
     * 
     * If the supply is 0, it means that the initial token has not been minted.
     * In this case we return the initalPrice.
     */
    function getPrice() public view returns(uint) {
        CAPSAToken CAPSA = CAPSAToken(CAPSAAddress);
        
        uint supply = CAPSA.totalSupply();
        uint tmpCapital = capital * 10 ** (priceDecimals + 1);
        if (supply == 0)
            return initalPrice;
        return ((tmpCapital / supply) + 5) / 10;
    }
    
    /**
     * Get the amount of CAPSA you will get in exchange of the given
     * amount of USDC.
     *
     * - amountUSDC: the amount of USDC you want to exchange
     */
    function getAmountCAPSA(uint amountUSDC) public view returns(uint) {
        uint price = getPrice();
        
        uint amount = ((amountUSDC * 10 ** (priceDecimals + 1) / price) + 5) / 10;
        return amount;
    }

    /**
     * Get the amount of USDC you can get in exchange of the given amount
     * of CAPSA.
     *
     * - amountCAPSA: the amount of CAPSA you want to exchange
     */
    function getAmountUSDC(uint amountCAPSA) public view returns(uint) {
        uint price = getPrice();
        
        uint amount = (amountCAPSA * price) / (10 ** priceDecimals);
        return amount;
    }
    
    /**
     * Swap USDC for CAPSA, for the given address.
     * This function will spend USDC of the given address and send freshly minted
     * CAPSA tokens to the address.
     *
     * - origin: the addres from which USDC will be spent
     * - destination: the addres on which CAPSA tokens will be sent
     * - amountUSDC: the amount of USDC to spend and convert in CAPSA
     */
    function _buyCAPSAFor(address origin, address destination, uint amountUSDC) private whenNotPaused {
        CAPSAToken CAPSA = CAPSAToken(CAPSAAddress);
        IERC20 USDC = IERC20(USDCAddress);
        require(
            USDC.allowance(origin, address(this)) >= amountUSDC,
            "You haven't allowed enough USDC to be spent by this contract for this transaction."
        );
        require(
            USDC.balanceOf(origin) >= amountUSDC,
            "You don't have enough USDC for this transaction."
        );
        require(
            destination != fundWallet,
            "capsa fund can't buy tokens directly."
        );
        require(
            destination != owner,
            "Owner can't buy tokens directly."
        );
        uint amountCAPSA = getAmountCAPSA(amountUSDC);
        USDC.transferFrom(origin, fundWallet, amountUSDC);
        CAPSA.mint(destination, amountCAPSA);
        capital += amountUSDC;        
    }

    /**
     * Swap USDC for CAPSA, for the transaction sender.
     *
     * - amountUSDC: the amount of USDC you want to spend for CAPSA
     */
    function buyCAPSA(uint amountUSDC) external whenNotPaused nonReentrant {
        _buyCAPSAFor(msg.sender, msg.sender, amountUSDC);
    }

    /**
     * Swap CAPSA for USDC, for the transaction sender.
     *
     * - amountCAPSA: the amount of CAPSA you want to spend for USDC
     */
    function sellCAPSA(uint amountCAPSA) external whenNotPaused nonReentrant {
        CAPSAToken CAPSA = CAPSAToken(CAPSAAddress);
        IERC20 USDC = IERC20(USDCAddress);

        require(
            CAPSA.allowance(msg.sender, address(this)) >= amountCAPSA,
            "You haven't allowed enough CAPSA to be spent by this contract for this transaction."
        );
        require(
            CAPSA.balanceOf(msg.sender) >= amountCAPSA,
            "You don't have enough CAPSA for this transaction."
        );

        uint amountUSDC = getAmountUSDC(amountCAPSA);
        require(
            USDC.balanceOf(fundWallet) >= amountUSDC,
            "Tne fund doesn't own enough USDC for this transaction."
        );
        require(
            USDC.allowance(fundWallet, address(this)) >= amountUSDC,
            "The fund wallet has not allowed this contract to spend its USDC"
        );
        CAPSA.burnFrom(msg.sender, amountCAPSA);
        USDC.transferFrom(fundWallet, msg.sender, amountUSDC);
        capital -= amountUSDC;
    }
}