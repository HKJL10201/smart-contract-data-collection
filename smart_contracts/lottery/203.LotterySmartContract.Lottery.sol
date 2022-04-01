// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract Lottery {
    enum State { Open, Closed }
    State public state;
    uint public entryFee;
    address[] entries;
    address contractManager;
    uint winningPlayerIndex;

    event NewEntry(address player);
    event LotteryStateChanged(State state);
	event PlayerDrawn(uint winningPlayerIndex);
    
    // modifier to be sure that the lottery is in the state it should be
    modifier isState(State _state) {
        require(state == _state, "Wrong state for this action");
        _;
    }
    
    // constructor
	constructor (uint _entryFee_in_wei, address _contractManager) {
		require(_entryFee_in_wei > 0, "Entry fee must be greater than 0");
		require(_contractManager != address(0), "Contract manager must be valid address");
		entryFee = _entryFee_in_wei;
		contractManager = _contractManager;
		changeState(State.Open);
	}
    
    // players can only submit entry if the lottery is open
    function submitEntry() public payable isState(State.Open) {
        require(msg.value >= entryFee * 1 wei, "Minimum entry fee required");
        require(msg.sender != contractManager, "Contract manager can't participate in the lottery.");
        entries.push(msg.sender);
        emit NewEntry(msg.sender);
    }
    
    // gets called by contract manager
    function finishLottery() public isState(State.Open){
        require(msg.sender == contractManager, "Only contract manager can finish the lottery.");

        // So in between finishing and resetting, no one can accidentally enter again
        changeState(State.Closed);

        drawPlayer();
    }
    
    // draw the winning player, pay him and reset the lottery
    function drawPlayer() private {
			winningPlayerIndex = random();
			emit PlayerDrawn(winningPlayerIndex);
			pay(entries[winningPlayerIndex]);
			reset();
	}
    
	// give money to winning player
	function pay(address winner) private {
		uint balance = address(this).balance;
		payable(winner).transfer(balance);
	}
	
	// reset the lottery so it can start again
    function reset() private {
        delete entries;
        changeState(State.Open);
	}
    
    // Simple function to change state
    function changeState(State newState) private {
		state = newState;
		emit LotteryStateChanged(state);
	}
	
	// warning from https://ethereum.stackexchange.com/questions/15641/how-does-a-contract-find-out-if-another-address-is-a-contract
	// --> EXTCODESIZE returns 0 if it is called from the constructor of a contract. So if you are using this in a security sensitive setting, you would have to consider if this is a problem.
	function isContract(address _addr) private view returns (bool iscontract){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
    
    // generates a random number of 
    function random() private view returns (uint) {
        uint number = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, entries)));
        uint rand = number % entries.length;
        return rand;
    } 
}
