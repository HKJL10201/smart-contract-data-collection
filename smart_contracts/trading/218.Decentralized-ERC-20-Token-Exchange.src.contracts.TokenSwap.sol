pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

//todos
//function to issue out LP token based on the provider's pool ownership 

contract TokenSwap {

	using SafeMath for uint256;

	string public name = "TokenSwap DEX";
	uint256 public dexLiquidity;
	address deployer;
 
	IERC20 token;
	IERC20 token2; 
	IERC20 lptoken;

	string[] public pairs;
	mapping (address => uint256) public liquidity;
	mapping (address => mapping (string => uint256)) public totalLiquidity;
	mapping (address => mapping (string => mapping (string => uint256))) public poolLiquidity;
	mapping (address => mapping (string => uint256)) public lptokenOwned;
	mapping (string => uint256) public pool; //ETH-DApp: "500"
	mapping (string => mapping (string => uint256)) public poolPair; //original liquidity regardless of trade - affected by new liquidity provided
	mapping (string => mapping (string => uint256)) public newPoolPair; //current post trade liquidity affected by trades

	event LiquidityProvided(address provider, string pair1, uint256 pair1Amount, string pair2, uint256 pair2Amount);
	event Traded(address trader, string pool, uint256 inputAmount, string inputToken, uint256 outputAmount, string outputToken);

	constructor(address _tokenAddress, address _lptokenAddress, address _token2Address) {
		token = IERC20(_tokenAddress);
		lptoken = IERC20(_lptokenAddress);
		token2 = IERC20(_token2Address);
		deployer = msg.sender;
	}

	function returnPairs() public view returns(string[] memory) {
		return pairs;
	}

	function issueLPToken(address _provider, uint256 _lptAmount, string memory _pairName) public {
		lptokenOwned[_provider][_pairName] = _lptAmount;
	}

	function initEthPair(uint256 _tokenAmount, string memory _pairName, string memory _pair1, string memory _pair2) public payable {
		require(_tokenAmount > 0);
		if (keccak256(abi.encodePacked(_pair2)) == keccak256(abi.encodePacked('DApp'))) {
			token.transferFrom(msg.sender, address(this), _tokenAmount);
		} else {
			token2.transferFrom(msg.sender, address(this), _tokenAmount);
		}
		liquidity[msg.sender] += _tokenAmount + msg.value;
		dexLiquidity += _tokenAmount + msg.value;
		pool[_pairName] += _tokenAmount + msg.value;
		totalLiquidity[msg.sender][_pairName] += _tokenAmount + msg.value;
		poolLiquidity[msg.sender][_pairName][_pair1] += msg.value;
		poolLiquidity[msg.sender][_pairName][_pair2] += _tokenAmount;
		poolPair[_pairName][_pair1] += msg.value;
		poolPair[_pairName][_pair2] += _tokenAmount;
		pairs.push(_pairName);
		emit LiquidityProvided(msg.sender, _pair1, msg.value, _pair2, _tokenAmount);
	}

	function addEthPair(uint256 _tokenAmount, string memory _pairName, string memory _pair1, string memory _pair2) public payable {
		require(_tokenAmount > 0);
		if (keccak256(abi.encodePacked(_pair2)) == keccak256(abi.encodePacked('DApp'))) {
			token.transferFrom(msg.sender, address(this), _tokenAmount);
		} else {
			token2.transferFrom(msg.sender, address(this), _tokenAmount);
		}
		liquidity[msg.sender] += _tokenAmount + msg.value;
		dexLiquidity += _tokenAmount + msg.value;
		pool[_pairName] += _tokenAmount + msg.value;
		totalLiquidity[msg.sender][_pairName] += _tokenAmount + msg.value;
		poolLiquidity[msg.sender][_pairName][_pair1] += msg.value;
		poolLiquidity[msg.sender][_pairName][_pair2] += _tokenAmount;
		poolPair[_pairName][_pair1] += msg.value;
		poolPair[_pairName][_pair2] += _tokenAmount;
		emit LiquidityProvided(msg.sender, _pair1, msg.value, _pair2, _tokenAmount);
	}

	function initTokenPair(uint256 _token1Amount, uint256 _token2Amount, string memory _pairName, string memory _pair1, string memory _pair2) public {
		require(_token1Amount > 0 && _token2Amount > 0);
		token.transferFrom(msg.sender, address(this), _token1Amount);
		token2.transferFrom(msg.sender, address(this), _token2Amount);
		liquidity[msg.sender] += _token1Amount + _token2Amount;
		dexLiquidity += _token1Amount + _token2Amount;
		pool[_pairName] += _token1Amount + _token2Amount;
		totalLiquidity[msg.sender][_pairName] += _token1Amount + _token2Amount;
		poolLiquidity[msg.sender][_pairName][_pair1] += _token1Amount;
		poolLiquidity[msg.sender][_pairName][_pair2] += _token2Amount;
		poolPair[_pairName][_pair1] += _token1Amount;
		poolPair[_pairName][_pair2] += _token2Amount;
		pairs.push(_pairName);
		emit LiquidityProvided(msg.sender, _pair1, _token1Amount, _pair2, _token2Amount);
	}

	function addTokenPair(uint256 _token1Amount, uint256 _token2Amount, string memory _pairName, string memory _pair1, string memory _pair2) public {
		require(_token1Amount > 0 && _token2Amount > 0);
		token.transferFrom(msg.sender, address(this), _token1Amount);
		token2.transferFrom(msg.sender, address(this), _token2Amount);
		liquidity[msg.sender] += _token1Amount + _token2Amount;
		dexLiquidity += _token1Amount + _token2Amount;
		pool[_pairName] += _token1Amount + _token2Amount;
		totalLiquidity[msg.sender][_pairName] += _token1Amount + _token2Amount;
		poolLiquidity[msg.sender][_pairName][_pair1] += _token1Amount;
		poolLiquidity[msg.sender][_pairName][_pair2] += _token2Amount;
		poolPair[_pairName][_pair1] += _token1Amount;
		poolPair[_pairName][_pair2] += _token2Amount;
		emit LiquidityProvided(msg.sender, _pair1, _token1Amount, _pair2, _token2Amount);
	}

	function tradeEthforToken(string memory _pairName, string memory _pair1, string memory _pair2) public payable {
		require(pool[_pairName] > 0, "No liquidity exists in this pool");
		uint256 pair1Balance; 
		uint256 pair2Balance;
		if (newPoolPair[_pairName][_pair1] == 0 && newPoolPair[_pairName][_pair2] == 0) {
			pair1Balance = poolPair[_pairName][_pair1];
			pair2Balance = poolPair[_pairName][_pair2];
		} else {
			pair1Balance = newPoolPair[_pairName][_pair1];
			pair2Balance = newPoolPair[_pairName][_pair2];
		}
		uint256 inputAmount = msg.value;
		require(pair1Balance > msg.value && pair2Balance > 0);
		uint256 poolConstant = pair1Balance * pair2Balance;
		uint256 inputAmountWithFee = inputAmount.mul(997);
		uint256 postTradePair2Balance = poolConstant.mul(1000) / (inputAmountWithFee.add(pair1Balance.mul(1000)));
		uint256 tokenTradeValue = pair2Balance.sub(postTradePair2Balance);
		require(pair2Balance > tokenTradeValue);
		if (keccak256(abi.encodePacked(_pair2)) == keccak256(abi.encodePacked('DApp'))) {
			token.transfer(msg.sender, tokenTradeValue);
		} else {
			token2.transfer(msg.sender, tokenTradeValue);
		}
		newPoolPair[_pairName][_pair1] = pair1Balance.add(inputAmount);
		newPoolPair[_pairName][_pair2] = pair2Balance.sub(tokenTradeValue);
		uint256 poolBal = pool[_pairName];
		poolBal = poolBal.add(inputAmount).sub(tokenTradeValue);
		pool[_pairName] = poolBal;
		dexLiquidity = dexLiquidity.add(inputAmount).sub(tokenTradeValue);
		emit Traded(msg.sender, _pairName, inputAmount, _pair1, tokenTradeValue, _pair2);
	}

	function tradeTokenforEth(uint256 _tokenAmount, string memory _pairName, string memory _pair1, string memory _pair2) public {
		require(pool[_pairName] > 0, "No liquidity exists in this pool");
		uint256 pair1Balance;
		uint256 pair2Balance;
		if (newPoolPair[_pairName][_pair1] == 0 && newPoolPair[_pairName][_pair2] == 0) {
			pair1Balance = poolPair[_pairName][_pair1];
			pair2Balance = poolPair[_pairName][_pair2];
		} else {
			pair1Balance = newPoolPair[_pairName][_pair1];
			pair2Balance = newPoolPair[_pairName][_pair2];
		}
		uint256 inputAmount = _tokenAmount;
		require(pair1Balance > 0 && pair2Balance > inputAmount);
		uint256 poolConstant = pair1Balance * pair2Balance;
		uint256 postTradePair1Balance = poolConstant.mul(1000) / (pair2Balance.mul(1000).add(inputAmount.mul(997)));
		uint256 etherTradeValue = pair1Balance.sub(postTradePair1Balance);
		require(pair1Balance > etherTradeValue);
		address payable trader = payable(msg.sender);
		if (keccak256(abi.encodePacked(_pair2)) == keccak256(abi.encodePacked('DApp'))) {
			token.transferFrom(msg.sender, address(this), inputAmount);
		} else {
			token2.transferFrom(msg.sender, address(this), inputAmount);
		}
		trader.transfer(etherTradeValue);
		newPoolPair[_pairName][_pair1] = pair1Balance.sub(etherTradeValue);
		newPoolPair[_pairName][_pair2] = pair2Balance.add(inputAmount);
		uint256 poolBal = pool[_pairName];
		poolBal = poolBal.add(inputAmount).sub(etherTradeValue);
		pool[_pairName] = poolBal;
		dexLiquidity = dexLiquidity.add(inputAmount).sub(etherTradeValue);
		emit Traded(msg.sender, _pairName, inputAmount, _pair2, etherTradeValue, _pair1);
	}

	function tradeTokenforToken(uint256 _tokenAmount, string memory _tradeToken, string memory _pairName, string memory _pair1, string memory _pair2) public {
		require(pool[_pairName] > 0, "No liquidity exists in this pool");
		uint256 pair1Balance;
		uint256 pair2Balance;
		if (newPoolPair[_pairName][_pair1] == 0 && newPoolPair[_pairName][_pair2] == 0) {
			pair1Balance = poolPair[_pairName][_pair1];
			pair2Balance = poolPair[_pairName][_pair2];
		} else {
			pair1Balance = newPoolPair[_pairName][_pair1];
			pair2Balance = newPoolPair[_pairName][_pair2];
		}
		uint256 inputAmount = _tokenAmount;
		uint256 tokenTradeValue;
		require(pair1Balance > 0 && pair2Balance > 0);
		uint256 poolConstant = pair1Balance * pair2Balance;
		if (keccak256(abi.encodePacked(_tradeToken)) == keccak256(abi.encodePacked(_pair1))) {
			uint256 postTradePairBalance = poolConstant.mul(1000) / (pair1Balance.mul(1000).add(inputAmount.mul(997)));
			tokenTradeValue = pair2Balance.sub(postTradePairBalance);
			require(pair2Balance > tokenTradeValue);
			token.transferFrom(msg.sender, address(this), inputAmount);//assumed that pair1 is token
			token2.transfer(msg.sender, tokenTradeValue);
			newPoolPair[_pairName][_pair1] = pair1Balance.add(inputAmount);
			newPoolPair[_pairName][_pair2] = pair2Balance.sub(tokenTradeValue);
		} else {
			uint256 postTradePairBalance = poolConstant.mul(1000) / (pair2Balance.mul(1000).add(inputAmount.mul(997)));
			tokenTradeValue = pair1Balance.sub(postTradePairBalance);
			require(pair1Balance > tokenTradeValue);
			token2.transferFrom(msg.sender, address(this), inputAmount);//assumed that pair2 is token2
			token.transfer(msg.sender, tokenTradeValue);
			newPoolPair[_pairName][_pair1] = pair1Balance.sub(tokenTradeValue);
			newPoolPair[_pairName][_pair2] = pair2Balance.add(inputAmount);
		}
		uint256 poolBal = pool[_pairName];
		poolBal = poolBal.add(inputAmount).sub(tokenTradeValue);
		pool[_pairName] = poolBal;
		dexLiquidity = dexLiquidity.add(inputAmount).sub(tokenTradeValue);
		emit Traded(msg.sender, _pairName, inputAmount, _tradeToken, tokenTradeValue, _pair2);
	}

	function withdraw(string memory _pairName, string memory _pair1, uint256 _pair1Amount, uint256 _pair2Amount, string memory _pair2, uint256 check1, uint256 check2) public {
		require(totalLiquidity[msg.sender][_pairName] > 0, "Can't withdraw from this pool");
		uint256 poolHold1 = poolLiquidity[msg.sender][_pairName][_pair1];//100ETH
		uint256 poolHold2 = poolLiquidity[msg.sender][_pairName][_pair2];//1000 DAPP
		uint256 poolLiquid1 = poolPair[_pairName][_pair1]; //150 ETH old
		uint256 poolLiquid2 = poolPair[_pairName][_pair2];//1500 DAPP
		uint256 tradeLiquid1 = newPoolPair[_pairName][_pair1];
		uint256 tradeLiquid2 = newPoolPair[_pairName][_pair2];
		require((check1 > _pair1Amount) && (check2 > _pair2Amount), "Can't take more than ownership portion");
		if (keccak256(abi.encodePacked(_pair1)) == keccak256(abi.encodePacked('ETH'))) {
			address payable trader = payable(msg.sender);
			trader.transfer(_pair1Amount);
			token.transfer(msg.sender, _pair2Amount);
		} else {
			token.transfer(msg.sender, _pair1Amount);
			token2.transfer(msg.sender, _pair2Amount);
		}
		poolLiquidity[msg.sender][_pairName][_pair1] = poolHold1.sub(_pair1Amount);
		poolLiquidity[msg.sender][_pairName][_pair2] = poolHold2.sub(_pair2Amount);
		poolPair[_pairName][_pair1] = poolLiquid1.sub(_pair1Amount);
		poolPair[_pairName][_pair2] = poolLiquid2.sub(_pair2Amount);
		newPoolPair[_pairName][_pair1] = tradeLiquid1.sub(_pair1Amount);
		newPoolPair[_pairName][_pair2] = tradeLiquid2.sub(_pair2Amount);
		uint256 totalWithdraw = _pair1Amount.add(_pair2Amount);
		pool[_pairName] -= totalWithdraw;
		dexLiquidity = dexLiquidity.sub(totalWithdraw);
	}
}




