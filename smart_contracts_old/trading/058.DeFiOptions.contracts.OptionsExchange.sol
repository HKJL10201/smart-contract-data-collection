pragma solidity >=0.5.16;

import "./AggregatorV3Interface.sol";

contract OptionsExchange {
	
	AggregatorV3Interface internal priceFeed;

    mapping (address => uint) public balances;
    mapping (uint => OrderData) private orders;
    mapping (address => OrderData[]) private buyerOrders;
    mapping (address => OrderData[]) private sellerOrders;
	
	uint serial = 1;
	uint volumeBase = 1e18;
	uint timeBase = 1e18;
	uint sqrtTimeBase = 1e9;
	uint seconds_in_day = 60 * 60 * 24;
	
	enum OrderType { LONG, SHORT }
	enum OptionType { CALL, PUT }
	
	struct OrderData {
		uint id;
		address payable buyer;
		address payable seller;
		uint price;
		uint volume;
		uint lowerVol;
		uint upperVol;
        OrderType _type;
        OptionData option;
		uint expiration;
    }
	
	struct OptionData {
        OptionType _type;
		uint strike;
		uint maturity;
    }

    constructor(address _priceFeedegator) public {
		priceFeed = AggregatorV3Interface(_priceFeedegator);
	}

    function sendOrder(
		address payable buyer,
		uint price,
		uint volume,
		uint lowerVol,
		uint upperVol,
		OrderType ordType,
		OptionType optType,
		uint strike, 
		uint maturity,
		uint expiration) payable public returns (uint id) {
			
        id = serial++;
		OptionData memory opt = OptionData(optType, strike, maturity);
		OrderData memory ord = OrderData(id, buyer, address(0), price, volume, lowerVol, upperVol, ordType, opt, expiration);
		orders[id] = ord;
		
		buyerOrders[ord.buyer].push(ord);
		
		addBalance(buyer);
		ensureFunds(buyer);
    }

    function confirmOrder(uint id, address payable seller) payable public {
		
		OrderData memory ord = orders[id];
		
		require(ord.id == id);
		require(ord.seller == address(0));
		require(ord.expiration > block.timestamp);
		
		ord.seller = seller;
		sellerOrders[ord.seller].push(ord);
		
		addBalance(seller);
		processPayment(ord);
		ensureFunds(seller);
    }
	
	function cancelOrder(uint id) public {
		
		OrderData memory ord = orders[id];
		
		require(ord.id == id);
		require(ord.buyer == msg.sender);
		require(ord.seller == address(0));
		
		orders[id].id = 0;
	}

    function closeOrder(uint id) public {
		
		OrderData memory ord = orders[id];
		require(ord.id == id);
		orders[id].id = 0;
		
		if (block.timestamp > ord.option.maturity) {
			
			int value = convertFromUsdToEth(intrinsicValueUsd(ord));
			if (value > 0) {
				removeBalance(ord.seller, uint(value));
				ord.buyer.transfer(uint(value));
			} else {
				removeBalance(ord.buyer, uint(value));
				ord.seller.transfer(uint(-value));
			}
			
		} else if (!hasRequiredMargin(ord.seller) && (ord._type == OrderType.LONG)) {
			
			uint reqMargin = calcMargin(ord.lowerVol, ord);
			removeBalance(ord.seller, reqMargin);
			ord.buyer.transfer(reqMargin);
			
		} else if (!hasRequiredMargin(ord.buyer) && (ord._type == OrderType.SHORT)) {
			
			uint reqMargin = calcMargin(ord.lowerVol, ord);
			removeBalance(ord.buyer, reqMargin);
			ord.seller.transfer(reqMargin);
			
		} else {
			
			revert();
			
		}
    }
	
	function addMargin(address addr) payable public {
		
		addBalance(addr);
	}
	
	function reclaimMargin() public {
		
		reclaimMargin(calcSurplus(msg.sender));
	}
	
	function reclaimMargin(uint amount) public {
		
		require(amount <= calcSurplus(msg.sender));
		removeBalance(msg.sender, amount);
		msg.sender.transfer(amount);
	}
	
	function calcMargin(address addr) public view returns (uint) {
		
		return convertFromUsdToEth(calcMarginUsd(addr));
	}
	
	function calcLowerMargin(uint id) public view returns (uint) {
		
		OrderData memory ord = orders[id];
		return calcMargin(ord.lowerVol, ord);
	}
	
	function calcUpperMargin(uint id) public view returns (uint) {
		
		OrderData memory ord = orders[id];
		return calcMargin(ord.upperVol, ord);
	}
	
	function calcIntrinsicValue(uint id) public view returns (int) {
		
		OrderData memory ord = orders[id];
		return convertFromUsdToEth(intrinsicValueUsd(ord));
	}
	
	function calcSurplus(address addr) public view returns (uint) {
		
		uint reqMargin = calcMargin(addr);
		if (balances[addr] >= reqMargin) {
			return balances[addr] - reqMargin;
		}
		return 0;
	}
	
	function addBalance(address addr) private {
		
		balances[addr] += msg.value;
	}
	
	function removeBalance(address addr, uint value) private {
		
		require(balances[addr] >= value);
		balances[addr] -= value;
	}
	
	function processPayment(OrderData memory ord) private {
		
		if (ord._type == OrderType.LONG) {
			removeBalance(ord.buyer, ord.price);
			ord.seller.transfer(ord.price);
		} else {
			removeBalance(ord.seller, ord.price);
			ord.buyer.transfer(ord.price);
		}
	}
	
	function ensureFunds(address addr) private view {
		
		require(hasRequiredMargin(addr));
	}
	
	function hasRequiredMargin(address addr) private view returns (bool) {
		
		return balances[addr] >= calcMargin(addr);
	}
	
	function calcMargin(uint vol, OrderData memory ord) private view returns (uint) {
		
		return convertFromUsdToEth(calcMarginUsd(vol, ord));
	}
	
	function convertFromUsdToEth(uint usd) private view returns (uint) {
		
		(,int answer,,,) = priceFeed.latestRoundData();
		return (1 ether * usd) / uint(answer);
	}
	
	function convertFromUsdToEth(int usd) private view returns (int) {
		
		(,int answer,,,) = priceFeed.latestRoundData();
		return int(1 ether * usd) / answer;
	}
	
	function calcMarginUsd(address addr) private view returns (uint) {
		
		uint i;
		int reqMargin = 0;
		
		for	(i = 0; i < buyerOrders[addr].length; i++) {
			OrderData memory ord = buyerOrders[addr][i];
			reqMargin -= intrinsicValueUsd(ord);
			if (ord._type == OrderType.SHORT) {
				reqMargin += int(calcMarginUsd(ord.upperVol, ord));
			}
		}
		
		for	(i = 0; i < sellerOrders[addr].length; i++) {
			OrderData memory ord = sellerOrders[addr][i];
			reqMargin += intrinsicValueUsd(ord);
			if (ord._type == OrderType.LONG) {
				reqMargin += int(calcMarginUsd(ord.upperVol, ord));
			}
		}
		
		if (reqMargin < 0)
		    return 0;
		return uint(reqMargin);
	}
	
	function calcMarginUsd(uint vol, OrderData memory ord) private view returns (uint) {
		
		return (vol * ord.volume * sqrt(daysToMaturity(ord.option))) / (sqrtTimeBase * volumeBase);
	}
	
	function intrinsicValueUsd(OrderData memory ord) private view returns (int value) {
		
		OptionData memory opt = ord.option;
		(,int answer,,,) = priceFeed.latestRoundData();
		int ethPrice = int(answer);
		int strike = int(opt.strike);

		if (opt._type == OptionType.CALL) {
			value = max(0, ethPrice - strike);
		} else if (opt._type == OptionType.PUT) {
			value = max(0, strike - ethPrice);
		} 
		
		value = (value * int(ord.volume)) / int(volumeBase);
		value = ord._type == OrderType.LONG ? value : -value;
	}
	
	function daysToMaturity(OptionData memory opt) private view returns (uint d) {
	    
	    if (opt.maturity > now) {
		    d = (timeBase * (opt.maturity - uint(now))) / seconds_in_day;
	    } else {
	        d = 0;
	    }
	}
	
	function sqrt(uint x) private pure returns (uint y) {
	
		uint z = (x + 1) / 2;
		y = x;
		while (z < y) {
			y = z;
			z = (x / z + z) / 2;
		}
	}
	
	function max(int a, int b) private pure returns (int) {
		
		return a > b ? a : b;
	}
	
	function min(int a, int b) private pure returns (int) {
		
		return a < b ? a : b;
	}
}