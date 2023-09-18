// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./erc20token.sol";

contract contractCapsa {
    function getPrice() public view returns(uint256) {}
    function buyCAPSA(uint amountUSDC) external {}
    function sellCAPSA(uint amountCAPSA) external {}
    function getAmountCAPSA(uint amountUSDC) public view returns(uint) {}
    function getAmountUSDC(uint amountCAPSA) public view returns(uint) {}
}


contract ldgSwap is Ownable, AccessControl {

    address tokenAddress = address(0x0); // LDG TOKEN ADDRESS
    address USDAddress = address(0x0); // USD ADDRESS
    address CAPSAddress = address(0x0); // CAPSA CONTRACT ADDRESS
    address fundWallet = address(0x0); // Fund Wallet
    address feeWallet = address(0x0); // Fee Wallet
    address tokenCapsAddress = address(0x0); // Capsa Token Address

    LDG01 token; // LDG TOKEN
    IERC20 token_usd;  // USD TOKEN
    contractCapsa capsa; // CAPSA CONTRACT
    IERC20 token_capsa; // CAPSA TOKEN

    bytes32 public constant FEE_ROLE = keccak256("FEE_ROLE"); // FEE ROLE TO CALL TakeFee in different wallet

    bool public depositPaused; // Pause Deposit
    bool public withdrawPaused; // Pause Withdraw

    /**
     * Pause / Unpause the deposit function.
     */
    function pause_deposit() external onlyOwner {
        depositPaused = !depositPaused;
    }

    /**
     * Pause / Unpause the widthdraw function.
     */
    function pause_withdraw() external onlyOwner  {
        withdrawPaused = !withdrawPaused;
    }

    constructor(address _USDAddress, address _CAPSAddress, address _CAPSATokenAddress, address _LDGTokenAddress, address _fundWallet, address _feeWallet, address _feeRoleLDG) {
        require(_USDAddress != address(0x0), "USD contract address cannot be 0x0.");
        require(_CAPSAddress != address(0x0), "CAPSA contract address cannot be 0x0.");
        require(_CAPSATokenAddress != address(0x0), "CAPSA token address cannot be 0x0.");
        require(_LDGTokenAddress != address(0x0), "Ledgity token address cannot be 0x0.");
        require(_fundWallet != address(0x0), "Fund wallet address cannot be 0x0.");
        require(_feeWallet != address(0x0), "Fee wallet address cannot be 0x0.");
        require(_feeRoleLDG != address(0x0), "Fee role address address cannot be 0x0.");

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(FEE_ROLE, _feeRoleLDG);

        capsa = contractCapsa(_CAPSAddress);
        CAPSAddress = address(_CAPSAddress);

        token_capsa = IERC20(_CAPSATokenAddress);
        tokenCapsAddress = address(_CAPSATokenAddress);

        token_usd = IERC20(_USDAddress);
        USDAddress = address(_USDAddress);

        token = LDG01(_LDGTokenAddress);
        tokenAddress = address(_LDGTokenAddress);

        fundWallet = address(_fundWallet);
        feeWallet = address(_feeWallet);
    }

    event allowanceFundWallet();
    uint256 balances_capsa; // total capsa registered

    uint8 priceDecimals = 6; // Decimals Token 1$ = 1000000

    uint32 public fee = 2000; // FEE in % // Decimals number for fee Percentage is 3 -> example 2250 = 2.25%
    uint256 public lastTimeFee = 0;
    // uint256 public feePeriod = 1 minutes; // Last timestamp at which the fee has been taken
    uint256 feePeriod = 1 days; // Last timestamp at which the fee has been taken
    uint32 ratio_time_fee = 360; // This value is used to divide the amount of fee we take for 1 year, for example -> 1 days fee period is 360 ratio_time_fee

    modifier isTokenSet() { // Check is all the address has been correctly set
        require(USDAddress != address(0x0), "USD Token address cannot be 0x0.");
        require(CAPSAddress != address(0x0), "CAPSA contract address cannot be 0x0.");
        require(tokenAddress != address(0x0), "Token LDG address cannot be 0x0.");
        require(fundWallet != address(0x0), "Fund Wallet address cannot be 0x0.");
        require(feeWallet != address(0x0), "Fee Wallet address cannot be 0x0.");
        require(tokenCapsAddress != address(0x0), "Token Capsa address cannot be 0x0.");
        _;
    }

    // ###### SET FUNCTIONS ######

    function setToken(address _token) external onlyOwner { // SET LDG TOKEN
        token = LDG01(_token);
        tokenAddress = address(_token);
    }

    function setTokenUSD(address _token) external onlyOwner { // SET USD TOKEN
        token_usd = IERC20(_token);
        USDAddress = address(_token);
    }

    function setFeeWallet(address _wallet) external onlyOwner { // SET FEE ADDRESS
        feeWallet = address(_wallet);
    }

    function setFee(uint32 _fee) external onlyOwner { // SET FEE
        require(_fee <= 100000, "You can't have more than 100% fee");
        fee = _fee;
    }

    function setFeePeriod(uint256 _feePeriod, uint32 _ratio_time_fee) external onlyOwner { // SET FEE PERIOD
        feePeriod = _feePeriod;
        ratio_time_fee = _ratio_time_fee;
    }

    function setFundWallet(address _wallet) external onlyOwner { // SET FUND WALLET
        fundWallet = address(_wallet);
    }

    // ###### IMPORTANT FUNCTIONS ######

    /**
     * Get the price of LTY in USDC.
     * 
     * If the supply is 0, it means that the initial token has not been minted.
     * In this case we return the initalPrice.
     */
    function myPrice() public view returns(uint) { // Price of the tokens LDG
        if (token.totalSupply() == 0 && balances_capsa == 0) {
            return (capsa.getPrice());
        }
        return (capsa.getAmountUSDC(balances_capsa) * 10 ** priceDecimals / token.totalSupply())       ;
    }

    /**
     * Deposit USDC for LTY
     * This function will spend USDC and send new minted LTY tokens to the address.
     */
    function deposit(uint256 amount) external isTokenSet { // DEPOSIT TOKENS USD VS LDG TOKEN
        require(depositPaused == false, "The deposit is paused");
        require(token_usd.balanceOf(msg.sender) >= amount, "You need to have enough USD in your balance");
        require(token_usd.allowance(msg.sender, address(this)) >= amount, "You need to approve USD to the contract");

        token_usd.approve(CAPSAddress, amount);
        require(token_usd.allowance(address(this), CAPSAddress) >= amount, "The contract has not allowed enough CAPSA Token on the contract to spend it");

        uint256 actualPrice = myPrice(); // Price of LDG
        uint256 amountCapsaBought = capsa.getAmountCAPSA(amount); // Amout capsa bought with the USD of the user

        bool res = token_usd.transferFrom(msg.sender, address(this), amount); // transfer all the USD in this contract
        require(res, "The Transfer has been failed, please try again.");

        capsa.buyCAPSA(amount); // SEND USD AND TAKE CAPSA
        token_capsa.transfer(fundWallet, amountCapsaBought); // transfer all the capsa bought to the fund wallet address
        token.mint(msg.sender, (amount * 10 ** priceDecimals) / actualPrice);   // TOKEN LDG MINT AND GIVE TO THE USERS
        balances_capsa += amountCapsaBought; // AMOUNT OF CAPSA ADDED TO THE BALANCES OF CAPSA
    }

    /**
     * Swap LTY for USDC
     */
    function withdraw(uint256 amount) external isTokenSet {
        require(withdrawPaused == false, "The withdraw is paused");
        require(token.balanceOf(msg.sender) >= amount, "You don't have enough money to withdraw.");

        uint256 amountCapsa = (balances_capsa * 10 ** 6) / token.totalSupply() * amount / (10 ** 6); // calcul of amount that we will need to withdraw
        uint256 giveUSD = capsa.getAmountUSDC(amountCapsa); // USD GIVE TO THE USER

        if (token_capsa.allowance(fundWallet, address(this)) < amountCapsa) {
            emit allowanceFundWallet();
        }
        require(token_capsa.allowance(fundWallet, address(this)) >= amountCapsa, "The fund wallet has not allowed enough CAPSA Token on the contract to spend it");

        token_capsa.approve(CAPSAddress, amountCapsa); // Approve Amount Capsa that we want withdraw
        require(token_capsa.allowance(address(this), CAPSAddress) >= amountCapsa, "The contract has not allowed enough CAPSA Token on the contract to spend it");

        token.burnFrom(msg.sender, amount); // BURN THE TOKEN THAT THE USER SENDED
        token_capsa.transferFrom(fundWallet, address(this), amountCapsa); // Transfer the capsa Token in this contract to sell it
        capsa.sellCAPSA(amountCapsa); // WITHDRAW AMOUNT OF THE CAPSA
        balances_capsa -= (amountCapsa); // AMOUNT WITHDRAW TO THE BALANCES OF CAPSA
        token_usd.transfer(msg.sender, giveUSD); // USD GIVE TO THE USER
    }

    /**
     * Take the fee in the balance
     */
    function takeFee() external isTokenSet {
        require(hasRole(FEE_ROLE, msg.sender), "You don't have role to take fee");
        require(lastTimeFee == 0 || lastTimeFee + feePeriod < block.timestamp, "You can't claim another fee right now wait until the end of the feePeriod");
        uint256 feeTake;

        lastTimeFee = block.timestamp;
        feeTake = (balances_capsa * fee / 100000) / ratio_time_fee; // calcul of the amount fee
        // balance capsa * the pourcentage fees with 3 decimals / 100000 instead of 100 because we have 3 decimals / ratio for 1 year (example 12 hours is 720)
        balances_capsa -= feeTake;
        token_capsa.transferFrom(fundWallet, feeWallet, feeTake); // TRANSFER FEE AMOUNT TO FEE WALLET
    }
}