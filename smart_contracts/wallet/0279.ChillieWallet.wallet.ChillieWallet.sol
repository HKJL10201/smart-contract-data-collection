// SPDX-License-Identifier: MIT
// Creator: Chillieman

/*
	Check us out at https://chillieman.com!

    Chillie Wallet is an upcoming mobile application that allows users to create Limit orders on any DEX they want.
    - Purchase a Token when it drops below a certain price.
    - Trade with ease by setting up a Take Gain, and allow Chillie Wallet to sell your tokens once the target price is reached.
    - Execute a Stop Loss to save your funds in a chrashing market.

    Chillie Token is the underlying ERC-20 token that fuels the Chille Wallet.
    - To use Chillie Wallet, the user must pay an activation fee using Chillie Token.
    - Activation Fees go directly to the Token contract, adding liquidity to make the Token more valuable.
    * Note: Users must approve Chillie Wallet to spend thier tokens as per ERC-20 - Or else this contract will be useless to the user.

    - When the Chillie Wallet application helps the user make money, a small tax of 0.1% is generated.
    - The taxes collected from wallet users must be processed manually by Chillieman - while processing :
      1. 50% is sent to Chillieman to continue innovation on the App.
      2. 50% is used to purchase Chillie Token, and then used to inject liquididty to the token.
        - Liquidity is automatically locked by sending the LP tokens directly to the ChillieToken Address.
*/

pragma solidity ^0.8.0;

import "./Context.sol";
import "./IUniswapV2Router.sol";
import "./IChillieToken.sol";

contract ChillieWallet is Context {
    address constant private _chillieman = 0x775E3bBFb07496dB8ed33A86Df0e41345f11Ea21;
    IChillieToken private _chillieToken;
    IUniswapV2Router02 private _uniswapV2Router;

	// Amount of ChillieTokens to pay each season to allow you to use ChillieWallet - Its free to start, and can be changed by Chillieman
	bool private _isChillieWalletSeasonActive;
	uint256 private _seasonFeeToUseWallet;

	// Data for tracking whether a Wallet User Has paid ChillieToken to activate the App during a season.
	address[] private _authorizedToUseWalletKeys;
	mapping (address => bool) private _isAuthorizedToUseWallet;

	// Data for tracking whether a Wallet User is paying thier Taxes
	address[] private _transactionKeys;
	mapping (bytes32 => bool) private _isTransactionPayedFor;
	
	//Chillie Wallet Events:
	event PaidWalletSeasonFees(address walletUser, uint256 amount);
	event PaidWalletTaxes(address walletUser, uint256 amount, bytes32 transaction);
	event ChillieWalletSeasonStarted(uint256 entryAmount);
	event ChillieWalletSeasonEnded();
    event ChillieWalletTaxesProcessed();

	modifier onlyChillie {
        require(_chillieman == _msgSender(), "Denied: caller is not Chillieman");
        _;
    }

    constructor(address chillieTokenAddress) {
        _chillieToken = IChillieToken(chillieTokenAddress);
        _uniswapV2Router = IUniswapV2Router02(_chillieToken.uniswapV2Router());

        _seasonFeeToUseWallet = 0;
        _isChillieWalletSeasonActive = false;
    }

    function uniswapV2Router() public view returns (address) {
		return address(_uniswapV2Router);
	}

    function chillieToken() public view returns (address) {
		return address(_chillieToken);
	}

    function chillieman() public pure returns (address) {
		return _chillieman;
	}
    
	function isChillieWalletSeasonActive() public view returns (bool) {
		return _isChillieWalletSeasonActive;
	}
	
	function getChillieWalletSeasonFee() public view returns (uint256) {
        return _seasonFeeToUseWallet;
    }
	
	function isTransactionPayedFor(bytes32 transaction) external view returns(bool) {
		return _isTransactionPayedFor[transaction];
	}
	
	function isAuthorizedToUseWallet(address walletUser) external view returns(bool) {
		return _isAuthorizedToUseWallet[walletUser];
	}
	
	function chillieStartWalletSeason(uint256 seasonFee) external onlyChillie {
		require(!_isChillieWalletSeasonActive, "Chillie Wallet is already in a season");
		
		_seasonFeeToUseWallet = seasonFee;
		_isChillieWalletSeasonActive = true;
		emit ChillieWalletSeasonStarted(seasonFee);
	}
	
	function chillieEndWalletSeason() external onlyChillie { 
		require(_isChillieWalletSeasonActive, "Chillie Wallet is not currently in season");
	
		// Iterate through the list of Authorized Wallet users, and delete them
		for (uint i=0; i < _authorizedToUseWalletKeys.length; i++) {
			// Delete this specific user from the mapping
			delete _isAuthorizedToUseWallet[_authorizedToUseWalletKeys[i]];
        }
		
		// Delete Keys
		delete _authorizedToUseWalletKeys;
	
		_isChillieWalletSeasonActive = false;
		emit ChillieWalletSeasonEnded();
    }

	function activateAccountForCurrentChillieWalletSeason(uint256 amount) payable external {
        // If Allowance isnt great enough, then call the approve method
		require(_isChillieWalletSeasonActive, "Chillie Wallet is not currently enabled");
		require(!_isAuthorizedToUseWallet[_msgSender()], "Wallet User is already Authorized!");
		require(amount == _seasonFeeToUseWallet, "Transaction Amount must be the same as Season Fee!");

		// Use of Chillie Wallet was not free this season, must transfer tokens to use the wallet.
		if(amount > 0) {
            require(_chillieToken.allowance(_msgSender(), address(this)) >= amount, "You need to add allowance so Chillie Wallet can use your tokens. - This should be taken care of by the App.");
			require(_chillieToken.balanceOf(_msgSender()) > amount, "Wallet User doesnt have the required Tokens");
			
            _chillieToken.transferFrom(_msgSender(), address(this), amount);
			// Transfer the Tokens from the Wallet user to This contract, then add the tokens directly to the Liquidity Pool!;
			_chillieToken.walletAddToLiquidityStash(amount);
		}

		//Add the Key, and set the User as authorized
		_authorizedToUseWalletKeys.push(_msgSender());
		_isAuthorizedToUseWallet[_msgSender()] = true;
		
        emit PaidWalletSeasonFees(_msgSender(), amount);
    }
	
	//This is a function that will be called when a Wallet User is charged a fee for a successful sale, where they made profit.
	// DO NOT DO A SWAP FOR EACH FEE PAYMENT! That would be chrging the Wallet users extra Network Fees. 
	// - Chillieman will pay all Network fees for the Wallet Stash processing.
	function payChillieWalletTax(uint256 amount, bytes32 transaction) payable external {
		require(_isChillieWalletSeasonActive, "Chillie Wallet is not currently enabled");
        require(_isAuthorizedToUseWallet[_msgSender()], "Wallet User is not Authorized!");
		require(!_isTransactionPayedFor[transaction], "Transaction has already been payed for!");
		require(amount > 0, "Transaction Amount cannot be zero!");
		require(msg.value == amount, "Transaction Amount is different than the ETH Provided!");
		
		// Figure out if this wallet is already in the List of people who will receieve tokens
		bool isMissingFromList = true;
		for (uint i=0; i < _transactionKeys.length; i++) {
			if(_transactionKeys[i] == _msgSender()) {
				isMissingFromList = false;
				break;
			}
        }
		
		if(isMissingFromList) {
			_transactionKeys.push(_msgSender());
		}

		// Add this transacton to the Paid list -> This will allow the address to continue using the ChillieWallet.
		// Chillie Wallet Application will take care of enforcing that profitable trades were taxed properly.
		_isTransactionPayedFor[transaction] = true;
        emit PaidWalletTaxes(_msgSender(), amount, transaction);
    }

	function chillieProcessWalletTaxes() external onlyChillie {
		require(address(this).balance > 0, "No Wallet Taxes to process");

		// Send half to Chillieman to continue Wallet Innovation
        payable(_chillieman).transfer(address(this).balance / 2);

		// With the other half, Buy Tokens and add to liquidity.
	    addLiquidityFromChillieWalletTaxes();

        emit ChillieWalletTaxesProcessed();
	}
    
	function addLiquidityFromChillieWalletTaxes() private returns (bool)  { 
		// Buy tokens
		uint256 tokensForLiquidity = buyTokens(address(this).balance / 2);

		// Then use them to add liquidity to Chillie Token
		_chillieToken.walletAddLiquidity{value: address(this).balance}(
			tokensForLiquidity,
			address(this).balance
		);

		return true;
    }
	
    function buyTokens(uint256 ethAmount) private returns(uint256 tokensReceived) {
		// TOKEN <-> WETH Pair
		address[] memory path = new address[](2);
        path[0] = _uniswapV2Router.WETH();
        path[1] = address(this);

		// Buy the tokens using ChillieToken
		return _chillieToken.walletBuyTokens{value: ethAmount}(ethAmount);
    }

	// To recieve ETH as donations 
	// - Half will be send to Chillieman & Half will be used to Inject Liquidity into ChillieToken
    receive() external payable {}

}
