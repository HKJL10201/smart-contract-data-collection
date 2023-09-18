pragma solidity >=0.5.16;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/OptionsExchange.sol";
import "../contracts/OptionsTrader.sol";
import "../contracts/AggregatorMock.sol";

contract TestOptionsExchange {
	
	uint public initialBalance = 10 ether;
	
	int ethInitialPrice = 550e8;
	uint one_day = 60 * 60 * 24;
	
	AggregatorMock feed;
	OptionsExchange exchange;
	
	OptionsTrader buyer;
	OptionsTrader seller;
	
	function beforeEachDeploy() public {
		
		feed = AggregatorMock(DeployedAddresses.AggregatorMock());
		exchange = OptionsExchange(DeployedAddresses.OptionsExchange());

		buyer = new OptionsTrader(address(exchange));
		seller = new OptionsTrader(address(exchange));
		
		feed.setPrice(ethInitialPrice);
	}

	function testLongCallIntrinsictValue() public {

		int step = 50e8;
		uint id = sendOrder(OptionsExchange.OrderType.LONG, OptionsExchange.OptionType.CALL, feed.getPrice(), 0);

		feed.setPrice(feed.getPrice() - step);
		Assert.equal(int(exchange.calcIntrinsicValue(id)), 0, "quote below strike");

		feed.setPrice(feed.getPrice() + step);
		Assert.equal(int(exchange.calcIntrinsicValue(id)), 0, "quote at strike");
		
		feed.setPrice(feed.getPrice() + step);
		int value = (1 ether * step) / feed.getPrice();
		Assert.equal(int(exchange.calcIntrinsicValue(id)), value, "quote above strike");
		
		Assert.equal(buyer.calcMargin(), 0, "long call margin");
	}

	function testLongPutIntrinsictValue() public {

		int step = 20e8;
		uint id = sendOrder(OptionsExchange.OrderType.LONG, OptionsExchange.OptionType.PUT, feed.getPrice(), 0);

		feed.setPrice(feed.getPrice() - step);
		int value = (1 ether * step) / feed.getPrice();
		Assert.equal(int(exchange.calcIntrinsicValue(id)), value, "quote below strike");

		feed.setPrice(feed.getPrice() + step);
		Assert.equal(int(exchange.calcIntrinsicValue(id)), 0, "quote at strike");
		
		feed.setPrice(feed.getPrice() + step);
		Assert.equal(int(exchange.calcIntrinsicValue(id)), 0, "quote above strike");
		
		Assert.equal(buyer.calcMargin(), 0, "long put margin");
	}

	function testShortCallIntrinsictValue() public {

		int step = 30e8;
		uint id = sendOrder(OptionsExchange.OrderType.SHORT, OptionsExchange.OptionType.CALL, feed.getPrice(), 125e15);

		feed.setPrice(feed.getPrice() - step);
		Assert.equal(int(exchange.calcIntrinsicValue(id)), 0, "quote below strike");

		feed.setPrice(feed.getPrice() + step);
		Assert.equal(int(exchange.calcIntrinsicValue(id)), 0, "quote at strike");
		
		feed.setPrice(feed.getPrice() + step);
		int value = -int((1 ether * step) / feed.getPrice());
		Assert.equal(int(exchange.calcIntrinsicValue(id)), value, "quote above strike");
		
		uint margin = uint(((ethInitialPrice * 1 ether / 8) / feed.getPrice()) - value);
		Assert.equal(buyer.calcMargin(), margin + 1 /* rounding error */, "short call margin");
	}

	function testShortPutIntrinsictValue() public {

		int step = 40e8;
		uint id = sendOrder(OptionsExchange.OrderType.SHORT, OptionsExchange.OptionType.PUT, feed.getPrice(), 125e15);

		feed.setPrice(feed.getPrice() - step);
		int value = -int((1 ether * step) / feed.getPrice());
		Assert.equal(int(exchange.calcIntrinsicValue(id)), value, "quote below strike");

		feed.setPrice(feed.getPrice() + step);
		Assert.equal(int(exchange.calcIntrinsicValue(id)), 0, "quote at strike");
		
		feed.setPrice(feed.getPrice() + step);
		Assert.equal(int(exchange.calcIntrinsicValue(id)), 0, "quote above strike");
				
		uint margin = uint((ethInitialPrice * 1 ether / 8) / feed.getPrice());
		Assert.equal(buyer.calcMargin(), margin, "short put margin");
	}
	
	function sendOrder(
		OptionsExchange.OrderType ordType,
		OptionsExchange.OptionType optType, 
		int strike,
		uint eth) private returns (uint id) {
			
		id = buyer.sendOrder.value(eth)(
			1 ether,
			1e18,
			uint(feed.getPrice() / 10),
			uint(feed.getPrice() / 8),
			ordType,
			optType,
			uint(strike), 
			now + one_day,
			now + one_day
		);
	}

}