// Based off of https://github.com/fivedogit/solidity-baby-steps/

// This contract is designed to demonstrate the generation of a random number.
// If you submit a betAndFlip() request after block 180,000 has just been mined,
// (i.e. when block 180,000 is the "best block" on stats.ethdev.gov and the most recent listed on any block explorer site),
// then the transaction will get mined/processed in block 180,001. (most of the time, anyway... it may be a block or two later)
// Once the transaction is mined, then block.number will become 180,002 while the flipping is underway.
// Any attempt to get blockhash(180,002) will return 0x000000000...
// That's why betAndFlip uses blocknumber - 1 for its hash.
// At first I thought "Wait, if we have to use the block in past, couldn't the gambler know that?" And the answer is "no".
// All the gambler knows at the time of bet submission is 180,000. We use 180,001 which is brand new and known and 180,002 is underway.

// NOTE: This contract is only meant to be used by you for testing purposes. I'm not responsible for lost funds if it's not bulletproof.
// 		 You can change msg.sender.send(...) to creator.send(...) in betAndFlip() to make sure funds only go back to YOUR account.
// NOTE: I don't know how this will behave with multiple potential bettors (or even just multiple bets) per block. It is meant for your single, one-per-block use only.
// NOTE: Use more gas on the betAndFlip(). I set mine to 1,000,000 and the rest is automatically refunded (I think). At current prices 9/3/2015, it's negligible anyway.

pragma solidity ^0.4.24;

contract CoinFlipper {
    address creator;
    int lastGameHouseProfit;
    string lastResult;
    uint lastBlockNumberUsed;
    bytes32 lastBlockHashUsed;

    constructor() public {
        creator = msg.sender;
        lastResult = "No wagers yet.";
        lastGameHouseProfit = 0;
    }

    function getEndowmentBalance() public constant returns (uint) {
        return address(this).balance;
    }

    // This is probably unnecessary and gas-wasteful. The lastBlockHashUsed should be random enough. Adding the rest of these deterministic factors doesn't change anything.
    // This does, however, let the bettor introduce a random seed by wagering different amounts. wagering 1 ETH will produce a completely different hash than 1.000000001 ETH
    // NOTE: This is pretty random... but not truly random.
    function sha(uint128 wager) constant private returns(uint256) {
        return uint256(keccak256(block.difficulty, block.coinbase, now, lastBlockHashUsed, wager));
    }

    function betAndFlip() payable public {
    	if (msg.value > 340282366920938463463374607431768211455) { 	// Value can't be larger than (2^128 - 1) which is the uint128 limit.
    		lastResult = "Wager too large.";
    		lastGameHouseProfit = 0;
    		msg.sender.transfer(msg.value); // Return wager.
    		return;
    	} else if ((msg.value * 2) > address(this).balance) { // Contract has to have 2*wager funds to be able to pay out. (current balance INCLUDES the wager sent)
    		lastResult = "Wager larger than contract's ability to pay off.";
    		lastGameHouseProfit = 0;
    		msg.sender.transfer(msg.value); // Return wager.
    		return;
    	} else if (msg.value == 0) {
    		lastResult = "Wager was zero.";
    		lastGameHouseProfit = 0;
    		return; // Nothing wagered, nothing returned.
    	}

    	uint128 wager = uint128(msg.value); // Limiting to uint128 guarantees that conversion to int256 will stay positive.

    	lastBlockNumberUsed = block.number - 1;
    	lastBlockHashUsed = blockhash(lastBlockNumberUsed);
    	uint128 lastBlockHashUsed_uint = uint128(lastBlockHashUsed) + wager;
    	uint randomUnsignedInt = sha(lastBlockHashUsed_uint);

	    if (randomUnsignedInt % 2 == 0) {
	    	lastGameHouseProfit = wager;
	    	lastResult = "The player lost.";
	    	return; // Player lost. Return nothing.
	    } else {
            lastGameHouseProfit = int(wager) * -1;
	    	lastResult = "The player won.";
	    	msg.sender.transfer(wager * 2); // Player won. Return bet and winnings.
	    }
    }

  	function getLastBlockNumberUsed() public constant returns (uint) {
        return lastBlockNumberUsed;
    }

    function getLastBlockHashUsed() public constant returns (bytes32) {
        return lastBlockHashUsed;
    }

    function getLastGameResult() public constant returns (string) {
    	return lastResult;
    }

    function getPlayerLossOnLastGame() public constant returns (int) {
    	return lastGameHouseProfit;
    }

    // Standard kill() function to recover funds
    function kill() public {
        if (msg.sender == creator) {
            // Kills this contract and sends remaining funds back to creator.
            selfdestruct(creator);
        }
    }
}
