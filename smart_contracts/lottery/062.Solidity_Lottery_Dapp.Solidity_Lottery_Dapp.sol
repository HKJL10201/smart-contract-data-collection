 // SPDX-License-Identifier: GPL-3.0

 pragma solidity >=0.5.0 <=0.9.0;


// ******* This SC do not produce totally random output for the winner. Thus Chainlink VRF is advised to generate random variable 

/*
1. Lottary starts by accepting ETH transactions. Anyone having an ETH wallet can send a fixed amount of 0.1 ETH to the contract's address.
2. The players send ETH directly to the contract address and their ETH address is registered. A user send more transactions having more changes
to win.
3. There is a manager, account that deploys and controls the contract.
4. At some point, if there are at least 3 players, he can pick a random winner from the player list. Only the manager is allowed to see contract
balance and to randomly select the winner.
5. The contract will transfer the entire balance to the winner's address and the lottery is reset and ready for the next round.

*/

contract Lottary {

    address payable[] public players;    // We will save the addresses of those who send Ether to our contract and entire the lottary
                                         // We don't know how many people will send ETH to lottery so we will declare a dynamic array called players.
                                         // Array is public so it can be easily accessed by external apps and anyone will be able to see array.

    address payable public previousGameWinner;   // Shows the previous game winner!
    
    // There are 2 types of addresses payable and non-payable

    address public manager; // -> EOA that deploys SC, starts lottery, picks winner and resets it for the next round.

    constructor() {
        manager = msg.sender;
    }

    receive() external payable {    // A contract can receive ETH if there is either a func called receive() or another one called fallback() 0.6
        require((msg.value ==  0.1 ether) && (msg.sender != manager));  // msg.value is a global variable that represents value of wei sent to the contract in a transaction.
        players.push(payable(msg.sender));  // Func cannot have arguments, cannot return anyhing, must have external visibility.

    }

    function getBalance() public view returns(uint) {
        require(msg.sender == manager);
        return address(this).balance;
    }

    function random() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));   

        // As these number always growing and changing, this will result in a random number just good for our lottery.
        
        /* This func takes a single argument type bytes 
        Since we want our number to be computed based on more random values, we call another function called abi.encodePacked()
        The func will perform packed encoding of the given arguments and return a variable of type bytes.
        Pay attention that this function is cannot be used in de-centralized lottery that has access to a large amount of ETH because
        it doesn't return a truly random number, the miners have the choice to publish a block or not.

        A random number system needs to be strong enough that even if an attacker knows exactly how you are creating the random number,
        the system remains unpredictable.

        A truly random number generation in Solidity must be done by sending a seed to an off chain resource, like an oracle, which must then return
        the generated random number and verifiable proof back to the smart contract.

        In SCS, the recommended way of generating random numbers, that deal with large amounts of ether is to use smg called Chainlink VRF
        
        */ 
    }

    /*

    function pickWinner() public view returns (uint) {
        require( (players.length >= 3) && (msg.sender == manager));
        uint winnerIndex = random() % players.length;
        return winnerIndex;
    }

    function transferToWinner() public returns(bool) {
        require(msg.sender == manager);
        address payable recipient = players[pickWinner()];
        uint amount = getBalance();
        recipient.transfer(amount);

        return true;
    }

    */ 

    function pickWinner() public {
        require( (players.length >= 3) && (msg.sender == manager));
        address payable winner = players[random() % players.length];
        uint amount = getBalance();
        winner.transfer(amount);
        previousGameWinner = winner;


        // Now we must reset the lottery, We will initialize the players state variable to an empty in-memory dynamic array. 

        players = new address payable[](0);  // resetting the lottery players array
    }
}

