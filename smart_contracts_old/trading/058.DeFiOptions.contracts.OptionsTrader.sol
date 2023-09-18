pragma solidity >=0.5.16;

import "./OptionsExchange.sol";

contract OptionsTrader {
	
	OptionsExchange exchange;
	address payable addr;
	
	constructor(address _exchange) public {
		exchange = OptionsExchange(_exchange);
		addr = address(uint160(address(this)));
	}

    function sendOrder(
		uint price,
		uint volume,
		uint lowerVol,
		uint upperVol,
		OptionsExchange.OrderType ordType,
		OptionsExchange.OptionType optType,
		uint strike, 
		uint maturity,
		uint expiration) payable public returns (uint id) {
			
        id = exchange.sendOrder
			.value(msg.value)
			(addr, price, volume, lowerVol, upperVol, ordType, optType, strike, maturity, expiration);
    }

    function confirmOrder(uint id) payable public {
		
		exchange.confirmOrder
			.value(msg.value)
			(id, addr);
    }
	
	function cancelOrder(uint id) public {
		
		exchange.cancelOrder(id);
	}

    function closeOrder(uint id) public {
		
		exchange.closeOrder(id);
    }
	
	function addMargin() payable public {
		
		exchange.addMargin
			.value(msg.value)
			(addr);
	}
	
	function reclaimMargin() public {
		
		exchange.reclaimMargin();
	}
	
	function reclaimMargin(uint amount) public {
		
		exchange.reclaimMargin(amount);
	}
	
	function calcMargin() public view returns (uint) {
		
		return exchange.calcMargin(addr);
	}
	
	function calcSurplus() public view returns (uint surplus) {
		
		return exchange.calcSurplus(addr);
	}
}