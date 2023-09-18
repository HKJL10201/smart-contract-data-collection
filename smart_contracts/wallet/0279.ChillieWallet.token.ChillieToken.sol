// SPDX-License-Identifier: MIT
// Creator: Chillieman

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router.sol";

/*
	Check us out at https://chillieman.com!

	Name: ChillieWallet (CHLL)
	Total Supply: 1,000,000,000,000 (1 Trillion)
	Maximum Wallet Amount: 10,000,000 (1% of supply) (10 Billion)
	Tokens to Liquidity: 100% (All)
	Initial Liquidity: 1 BNB
	Starting Price: 0.000000001 BNB
	Taxes: 1% for Development Stash (Will be discontinued once the wallet begins generating taxes)
	Taxes: 9% for Liquidity Stash

	Liquidity Stash is processed when it reaches 1% of total supply.
	The LP Token is automatically locked into ChillieToken for 1 year when generated.
	Every time the Liquidity Stash is processed, this 1 year timer is reset.

	The true purpose of this token is to be used by a mobile application called ChillieWallet!
	ChillieWallet povides the ability to use Limit Orders, and preprogrammed execution of trades. 
	Fees are generated by ChillieWallet and sent to Token. When those Fees are processed:
	- 50% of the Wallet Taxes goes to Chillieman, to continue Development on the wallet.
	- 50% of the Wallet Taxes goes to adding more liquidity
	
	The Chillie Wallet is a separate Smart Contract, Which addess will be posted on our website, so give us a look!
*/

contract ChillieToken is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    //We have to allow Exchange Wallets to hold more than 1% of the supply
	mapping (address => bool) private _isExcludedFromTokenLimit;
	
	// Taxes will Only change if Chillieman turns off the Dev Taxes (In this case, all Taxes will goto Liquidity Stash)
	// - The taxes can also be disabled across the whole network, for special events, holidays, and migrations.
    uint256 private _devTax = 1;
    uint256 private _liquidityTax = 9;
    uint256 constant private _percentageAfterTax = 90;
    address constant private _chillieman = 0x775E3bBFb07496dB8ed33A86Df0e41345f11Ea21;
	address constant private _chillieBakedAddress = 0x00000000000000000000000000000000000fAdED;

	// Chillie Wallet Contact Address - Will be set by Chillieman once the Wallet Contract is created.
	address private _chillieWalletAddress;

    // Fees are either on or off, if this is false, taxes will not be collected.
	// Consider doing Special Events where there are NO taxes for Holidays!
	bool private _isTaxEnabled = true;

	 // This will get set to true once Chillie calls chillieRemoveExemptions()
	bool private _isChilliemanRequiredToPayTax = false;

    // Running Amount of how much taxes have been collected.
    uint256 private _liquidityStash = 0;
    uint256 private _devStash = 0;
	
	// All the liquidity is locked up for a full year, every time new Liquidity is auto generated.
	uint constant YEAR_IN_SECONDS = 31536000;
	uint256 private _liquidityUnlockTime = block.timestamp + YEAR_IN_SECONDS;

	// Prevents multiple transactions from attempting to generate liquidity at the same time
    bool private _isLiquidityBeingGenerated = false;

	string private constant _name = "ChillieWallet";
    string private constant _symbol = "CHLL";
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 10**12 * 10**_decimals; // 1 Trillion Tokens
    uint256 private _maxTokenAmount = 10**10 * 10**_decimals; // 10 Billion Tokens

    IUniswapV2Router02 private _uniswapV2Router;
    IUniswapV2Pair private _uniswapV2Pair;
	
	//Emitted when an exchange is added or removed to the _isExcludedFromTokenLimit list.
	event ExchangeAdded(address exchangeAddress);
	event ExchangeRemoved(address exchangeAddress);

	//Emitted when the contract is adding Liquidity.
	event LiqudidityPurchased(uint256 liquidityTokensReceived, uint256 ethRemaining,  uint256 tokensRemaining);
	
	//Emitted if there is ever a time where the Contract tries to buy Liquidity with more tokens than it owns.
	event LiquidityAccountingError(string message, uint256 expectedAmount, uint256 actualAmount);

	// Emitted whne Chillieman removes himself from Tax Exemption (This is done after Chillieman supplies all tokens to PancakeSwap)
	event ChilliemanIsNowLimited();
	
	// Emitted when Chillieman removes all collection of Dev Stash. -> All 10% of taxes will then go towards Liquidity
	event DevTaxesRemoved(string message);
	
	// Emitted when Chillieman is claiming the Dev Stash
	event DevTaxesClaimed(uint256 amountClaimed, uint256 expectedAmount);
	event DevClaimError(string message, uint256 expectedAmount, int256 actualAmount);
	
	// Emitted If the token is a failure and hasnt had activity for over a year - Dev can then transfer the liquidity to themselves.
	event LiquidityUnlocked(address pairAddress, address to, uint256 amount);

	// Emitted when the Wallet adds tokens to the liquidity stash (when Season Fees are paid to activate wallet)
	event LiquiditiyAddedFromWallet(uint256 tokenAmount); 
    
    modifier lockLiquidityGeneration {
        _isLiquidityBeingGenerated = true;
        _;
        _isLiquidityBeingGenerated = false;
    }
	
	modifier onlyChillie {
        require(_chillieman == _msgSender(), "Denied: caller is not Chillieman");
        _;
    }

	modifier onlyWallet {
        require(_chillieWalletAddress == _msgSender(), "Denied: caller is not ChillieWallet");
        _;
    }

    constructor() {
        _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        address pairAddress = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

		_uniswapV2Pair = IUniswapV2Pair(pairAddress);

		_balances[_chillieman] += _totalSupply;
        emit Transfer(address(0), _chillieman, _totalSupply);

        //exclude Chillieman, Burn Address, this contract from Maximum Token Limit
        _isExcludedFromTokenLimit[_chillieman] = true;
        _isExcludedFromTokenLimit[_chillieBakedAddress] = true;
		_isExcludedFromTokenLimit[address(this)] = true;
        _isExcludedFromTokenLimit[pairAddress] = true;
		
		// Allow Router to hold more than Max Amount - This is the initial Exchange
		chillieAddExchange(address(_uniswapV2Router));
    }

	//Once the Wallet has been Deployed, add the address here
	function chillieWalletAddress() public view returns(address chilieWalletAddress) {
		return _chillieWalletAddress;
	}

	function chillieman() public pure returns (address) {
		return _chillieman;
	}

	function chillieBakedAddress() public pure returns (address) {
		return _chillieBakedAddress;
	}
	function isTaxEnabled() public view returns (bool) {
		return _isTaxEnabled;
	}

	function uniswapV2Router() public view returns (IUniswapV2Router02) {
		return _uniswapV2Router;
	}

	function uniswapV2Pair() public view returns (IUniswapV2Pair) {
		return _uniswapV2Pair;
	}

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

	function maxTokenAmount() public view returns (uint256) {
        return _maxTokenAmount;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function getSecondsUntilLiquidityUnlockTime() public view returns (uint256) {
        return _liquidityUnlockTime - block.timestamp;
    }

	function devStash() public view returns (uint256) {
        return _devStash;
    }
	
	function liquidityStash() public view returns (uint256) {
        return _liquidityStash;
    }

	function isChilliemanRequiredToPayTax() public view returns(bool) {
        return _isChilliemanRequiredToPayTax;
    }
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
    
    function calculateDevFee(uint256 amount) private view returns (uint256) {
		if(_devTax > 0) {
			return amount * _devTax / 10**2;
		}
		return 0;
    }

    function calculateLiquidityFee(uint256 amount) private view returns (uint256) {
        return amount * _liquidityTax / 10**2;
    }

    function calculateAfterTaxAmount(uint256 amount) private pure returns (uint256) {
        return amount * _percentageAfterTax / 10**2;
    }
	
	function calculateMaximumReceiveAmountWithTaxes(uint256 amount) private pure returns (uint256 maxReceiveAmount) {
		return amount * 10**2 / _percentageAfterTax;
	}
	
    function isExcludedFromTax(address account) private view returns(bool) {
		// Exclude Chillie From tax at first, that way all tokens can be supplied to the Router.
		// Once the initial exchange is funded, call the removeChilliemanTaxExemption() function so Chillieman gets taxed just like everyone else!
        return (account == _chillieman && !_isChilliemanRequiredToPayTax) ||
			account == _chillieWalletAddress || // Gifts sent by Chillie Wallet are not taxed
			account == address(this);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

	function howManyTokensSoldToGet(uint256 ethAmount) external view returns (uint256) {
		address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

		//Ask PancakeSwap how many tokens i need to see to get ethAmount
		uint[] memory amounts = _uniswapV2Router.getAmountsIn(ethAmount, path);

		return uint256(amounts[0]);
	}

	// If you already hold some ETH, sell less tokens to try and get the ratio closer when adding Liquidity
	// This is all in an effort to get Every last BNB into liquidity, not just sitting in the Contract.
	// Minimumal Crumbs, brought to you by Chillieman!
    function generateLiquidity() private lockLiquidityGeneration {
		uint256 tokensForLiquidity = balanceOf(address(this)) - _devStash;

		//Chilliemans Secret Formula: Attmpting to jam every shred of ETH into liquidity!
		// - Steal away ^_^
		try this.howManyTokensSoldToGet(address(this).balance) returns (uint256 tokensNeededToMatchBalanceWorth) {
			// If The tokens in the liquidity Stash are not as valuable as the ETH you hold, then you dont need to sell any tokens
			// Just add everything you have to Liquidity

            if(tokensNeededToMatchBalanceWorth < tokensForLiquidity) {
				uint256 amountOfTokensToSell = (tokensForLiquidity / 2) - (tokensNeededToMatchBalanceWorth / 2);
				sellTokens(amountOfTokensToSell);
			}
        } catch {
			// Check if the Amount of ETH you own exceed the reserves.... If it does, then DONT sell tokens
			(,uint112 ethReserve,) = _uniswapV2Pair.getReserves();

			if(address(this).balance < uint256(ethReserve)) {
				// Old but gold!
				sellTokens(tokensForLiquidity / 2);
			}
        }

		//Epic!! *poggers*
		
        (, uint256 leftOverTokens) = addLiquidity(balanceOf(address(this)) - _devStash, address(this).balance);

		_liquidityStash = leftOverTokens;
    }


    function sellTokens(uint256 tokenAmount) private returns(uint256 tokensReceived) {
		// See how many Tokens 
        _approve(address(this), address(_uniswapV2Router), type(uint256).max);

		// TOKEN <-> WETH Pair
		address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        uint256 balanceBefore = address(this).balance;

        // Sell the tokens
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount
            path,
            address(this),
            block.timestamp
        );

        uint256 balanceAfter = address(this).balance;
		
		// Return the amount of ETH received
		return balanceAfter - balanceBefore; 
    }
	
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private returns(uint256 remainingETH, uint256 remainingTokens) {
        _approve(address(this), address(_uniswapV2Router), type(uint256).max);

		uint256 tokensSent;
		uint256 ethSent;
		uint256 liquidityTokensReceived;

        // add the liquidity, accounting for any left over tokens or eth
        (tokensSent, ethSent, liquidityTokensReceived) = _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this), // Send Liquidity to ChillieToken Vault, not the owner!
            block.timestamp 
        );

		uint256 returnTokens = tokenAmount - tokensSent;
		uint256 returnEth = ethAmount - ethSent;
		
		// Reset the timer responsible for controlling the lock time of liquidity.
		// Each time this function is called, the liquidity timer gets reset for a full year.
		_liquidityUnlockTime = block.timestamp + YEAR_IN_SECONDS;

		emit LiqudidityPurchased(liquidityTokensReceived, returnEth, returnTokens);

		return(returnEth, returnTokens);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        // Deter whales that could crash the token! Normal Addresses cannot have more than 1% of the supply!
		uint256 recipientBalance = balanceOf(address(to));
		if(!_isExcludedFromTokenLimit[to]) {
			// Ensure that this wallet does not exceed Max Limit after taxes are removed.
			// Emit the Maximum amount of Tokens that can be recieved using a require statment.
			if(_isTaxEnabled) {
				require(recipientBalance + calculateAfterTaxAmount(amount) <= _maxTokenAmount, "Accounts can only 1% of the token supply, Receiver cannot accept this much.");
			} else {
				require(recipientBalance + amount <= _maxTokenAmount, "Accounts can only hold 1% of the token supply, Receiver cannot accept this much.");
			}
		}

        // Is there enough tokens in the Liquidity Vault to Add to Liquidity?
        bool isOverMinTokenBalance = _liquidityStash >= _maxTokenAmount;
        if (isOverMinTokenBalance && !_isLiquidityBeingGenerated && from != address(_uniswapV2Pair)) {
            generateLiquidity();
        }
        
        // Indicates if fee should be deducted from transfer
        if(isExcludedFromTax(to) || isExcludedFromTax(from) || !_isTaxEnabled){
            chillieTransfer(from, to, amount, false);
        } else {
			chillieTransfer(from, to, amount, true); // Not a special event, taxes are enabled.
		}
    }

    function chillieTransfer(address from, address to, uint256 amount, bool isCollectTax) private {
		uint256 tokensToTransfer = amount;
		
		if(isCollectTax) {
			// tokensToTransfer will be the remainder after taxes were taken
            tokensToTransfer = takeTaxes(from, amount);
		}
		
        _balances[from] -= tokensToTransfer;
        _balances[to] += tokensToTransfer;
        emit Transfer(from, to, tokensToTransfer);
    }
	
	function takeTaxes(address from, uint256 amount) private returns (uint256) {
		// Chillie - Add Tokens to this contract, and add them to the Liqudidity and Dev stashes
		uint256 feeLiquidity = calculateLiquidityFee(amount);
		_balances[address(this)] += feeLiquidity;
		_balances[from] -= feeLiquidity;
		_liquidityStash += feeLiquidity;
		
		uint256 feeDevelopment = calculateDevFee(amount);
		if(feeDevelopment > 0) {
			_balances[address(this)] += feeDevelopment;
			_balances[from] -= feeDevelopment;
			_devStash += feeDevelopment;
		}
		
		uint256 totalTaxes = feeLiquidity + feeDevelopment;
		uint256 totalRemainingTokens = amount - totalTaxes;
		
		// Sum up the amount of Taken Tokens, and Emit a transfer to this Contract - Audits the tax collection
		emit Transfer(from, address(this), totalTaxes);
		
		//After taxes have been taken, return the amount of tokens left for the recipient
		return totalRemainingTokens;
    }


	// -- Chillieman Maintenance Functions -- //
	
	function chillieToStandardAccount() external onlyChillie {
		require(!_isChilliemanRequiredToPayTax, "Chillieman is already a normal trader.");
		// Called upon creation of Token - Makes Chillieman a normal trader.
		_isChilliemanRequiredToPayTax = true;
		_isExcludedFromTokenLimit[_chillieman] = false; 
		emit ChilliemanIsNowLimited();
	}

	function chillieSuspendTaxes() external onlyChillie {
		require(_isTaxEnabled, "Taxes are not enabled!");
		_isTaxEnabled = false;
    }
	
	function chillieResumeTaxes() external onlyChillie {
		require(!_isTaxEnabled, "Taxes are already enabled!");
        _isTaxEnabled = true;
    }
	
	function chillieAddExchange(address account) public onlyChillie {
		require(!_isExcludedFromTokenLimit[account], "Exchange is already Added");
        _isExcludedFromTokenLimit[account] = true;
		emit ExchangeAdded(account);
    }
    
    function chillieRemoveExchange(address account) external onlyChillie {
		require(_isExcludedFromTokenLimit[account], "This is not an Exchange");

		// Make sure the core accounts cannot be removed from this list!
		require(account != address(this), "Cant Remove This address!");
		require(account != _chillieBakedAddress, "Cant Remove the Burn Address!");
		require(account != address(_uniswapV2Router), "Cant Remove the Initial Router!");
		require(account != address(_uniswapV2Pair), "Cant Remove the Liquidity Pair!");
		require(account != _chillieWalletAddress, "Cant Remove the Wallet Address!");

        _isExcludedFromTokenLimit[account] = false;
		emit ExchangeRemoved(account);
    }

	function chillieDiscontinueDevTaxes() external onlyChillie {
		// Once the Wallet is live and kicking, Stop collecting Dev Taxes on the Token
		_liquidityTax += _devTax;
		_devTax = 0;
		
		// Add any remaining tokens from the Dev Stash to the Liquidity Stash.
		_liquidityStash += _devStash;
		_devStash = 0;
		
		// Broadcast the good news!
		emit DevTaxesRemoved("Chillieman has removed the Development Tax for this token - All taxes will now go towards Liquidity!");
	}


	// -- Chillieman Reward Function -- //
	function chillieClaimDevelopmentTax() public onlyChillie {
		require(_devStash > 0, "No Development Taxes to claim");
		//Never take from the liquidity fund!! - This is a failsafe in case there is an unexpected error from tax collection
		require(balanceOf(address(this)) - _liquidityStash > 0, "Balance - Liquidity Stash is not greater than 0");
		
		uint256 devReward = _devStash;
		uint256 leftOver = 0;

		// Dont Allow Chillieman to claim more than a wallet can hold.
		if(devReward > _maxTokenAmount) {
			devReward = _maxTokenAmount;
			leftOver = _maxTokenAmount - devReward;
		}

		// The contract is working as intended, and there are indeed DevRewards available!
		address from = address(this);
		_transfer(from, _chillieman, devReward);
		emit DevTaxesClaimed(devReward, _devStash); // These should match!
	
		_devStash = leftOver;
    }

	// -- Chillieman Failure Function -- //
	function unlockLiquidity() external onlyChillie {
		require(_liquidityUnlockTime <= block.timestamp, "You cannot unlock the liquidity yet");
		
		// Wow.... its been a full year and Liquidity wasnt generated.... what an absolute failure =[
		uint256 liquidityTokenBalance = _uniswapV2Pair.balanceOf(address(this));
		
		require(liquidityTokenBalance > 0, "There is no liquidity here!");
		
	
		// If the transfer was successful, emit the Withdrawl
		bool isSuccess = _uniswapV2Pair.transfer(_chillieman, liquidityTokenBalance);
		if(isSuccess) {
			emit LiquidityUnlocked(address(_uniswapV2Pair), _chillieman, liquidityTokenBalance);
		}

		_maxTokenAmount = _totalSupply;
	}

	// -- Set the Wallet, allows the ChillieWallet contract use the below Functions -- //
	function chillieSetWalletAddress(address walletAddess) external onlyChillie {
		require(walletAddess != _chillieWalletAddress, "Wallet already set!");
		if(_isExcludedFromTokenLimit[_chillieWalletAddress]) {
			//Existing Wallet - Migration for Chillie Wallet update. Deactivate old Wallet
			_isExcludedFromTokenLimit[_chillieWalletAddress] = false;
		}

		// Chillie Wallet needs power to add liquidity, and will reward Chillie Wallet users without taxation.
		_isExcludedFromTokenLimit[walletAddess] = true;
		_chillieWalletAddress = walletAddess;
	}

	// -- Special functions that can only be called by ChillieWallet =] -- //

	function walletAddToLiquidityStash(uint256 amount) external onlyWallet returns (bool){
		// Wallet Transfers token directly into Liquidity Stash
		chillieTransfer(_chillieWalletAddress, address(this), amount, false);
		_liquidityStash += amount;

		emit LiquiditiyAddedFromWallet(amount);

		return true;
	}

	function walletBuyTokens(uint256 amount) payable external onlyWallet returns(uint256 tokensReceived) {
		require(amount > 0, "Transaction Amount cannot be zero!");
		require(msg.value == amount, "Transaction Amount is different than the ETH Provided!");

		// TOKEN <-> WETH Pair
		address[] memory path = new address[](2);
        path[0] = _uniswapV2Router.WETH();
        path[1] = address(this);

        uint256 tokenBalanceBefore = balanceOf(address(_chillieWalletAddress));

		// Buy the tokens
		_uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
			0, // Accept any amount
			path,
			_chillieWalletAddress,
			block.timestamp 
		);
		
        uint256 tokenBalanceAfter = balanceOf(address(_chillieWalletAddress));

		uint256 tokens = tokenBalanceAfter - tokenBalanceBefore;

		// Return the amount of tokens received
		return tokens;
    }

	function walletAddLiquidity(uint256 tokenAmount, uint256 ethAmount) payable external onlyWallet returns(bool) {
		require(ethAmount > 0, "Transaction Amount cannot be zero!");
		require(tokenAmount > 0, "Transaction Token Amount cannot be zero!");
		require(msg.value == ethAmount, "Transaction Amount is different than the ETH Provided!");
		require(balanceOf(_chillieWalletAddress) >= tokenAmount, "Not Enough Tokens in ChillieWallet!");

		//Transfer Tokens here to add to Liquidity with
		chillieTransfer(_chillieWalletAddress, address(this), tokenAmount, false);

		uint256 tokensLeftOver;

		//Allow PancakeSwap to use Chillie Wallets tokens before adding liqudidity.
		_approve(_chillieWalletAddress, address(_uniswapV2Router), type(uint256).max);
		(, tokensLeftOver) = addLiquidity(tokenAmount, ethAmount);

		//Add Any left overs to the liquidity stash.
		_liquidityStash += tokensLeftOver;

		//If you received a rediculous amount of liquidity, then generate more liquidity the opposite direction by selling your tokens (You probably are left with TONS if the injected liquidity is massive)
		//This is extremely important when starting on a brand new blockchain - As the wallet may be processing taxes that are enormous compared to the current liquidity pool.
		if(_liquidityStash >= _maxTokenAmount) {
			generateLiquidity();
		}
		return true;
    }
	
}