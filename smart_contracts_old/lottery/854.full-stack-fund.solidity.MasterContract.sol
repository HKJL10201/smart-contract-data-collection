pragma solidity ^0.4.0;
import "./Lottery.sol";

contract MasterContract {
    address public owner;
    Lottery[] public lotteries;
    address public newLotteryAddress;
    
    event eLog (
        address indexed _from,
        string value
    );

    function MasterContract () public payable {
        owner = msg.sender;
    }

    // TODO - If openlottery with same etherContribution, maxPlayers, then call addActivePlayer on that lottery, otherwise, continue below...
    // don't need _etherContribution, use msg.value instead? but what they're declaring should match what they're sending...Design choice...
    // TODO - Evaluate if we need to use Lottery[], because its difficult to remove lotteries from Lottery[] once they're completed
    // msg.value goes to the new lottery contract because of .value(msg.value), and user's invocation had {value: web3.toWei(1, 'ether')}
    // .addActivePlayer takes in msg.value as a arbitrary number
    function createLottery(uint _etherContribution, uint _maxPlayers) public payable {
        Lottery newLottery = (new Lottery).value(msg.value)(_etherContribution, _maxPlayers, owner);
        newLottery.addActivePlayer(owner, msg.value); // delegate call to set msg.sender in Lottery as same addr as msg.sender in MasterContract
        newLotteryAddress = address(newLottery);
        lotteries.push(newLottery);
    }

    // Only can be called by a address that's in lotteries[]
    // throw; ERRORS, needs revert()    
    modifier onlyBy {
        emit eLog(msg.sender, "onlyBy....");

        // Search lottieres[] and make sure _lotteryAddress is in it
        uint256 numLotteries = lotteries.length;
        for (uint i = 0; i < numLotteries; i++) {
            Lottery lottery = lotteries[i];
            // if (lottery.address == msg.sender) {
            if (lottery == msg.sender) {
                emit eLog(msg.sender, "modifier - REMOVE the lottery, it was called by right contract, itself");
                _;
            }
        }
        // revert();
    }

    // Modifier - only if the msg.sender IS the lottery contract address (AND it was in Lottery[]?)
    // no one has privateKey/ability to imitate the Lottery Contract being the caller/msg.sender?
    // i.e.
    // can use a better keyword than public? what if make private?
    // set exclusive access
    // Return BOOL so don't need 'public payable' to suppress warning, "Function state mutability can be restricted to pure function removeLottery() public { ^ (Relevant source part starts here and spans across multiple lines)."
    // function removeLottery(address _lotteryAddress) onlyBy public payable { // DON'T NEED arg, can use msg.sender instead
    function removeLottery() onlyBy public payable {
                  
        emit eLog(msg.sender, "removeLottery - REMOVE it");                    
        
        address lotteryToRemove = msg.sender;
        uint256 numLotteries = lotteries.length;
        for (uint i = 0; i < numLotteries; i++) {
            Lottery lottery = lotteries[i];
            if (lottery == lotteryToRemove) {
                emit eLog(msg.sender, "removing.....delete");
    
                for (uint index = i; index < numLotteries-1; i++){
                    lotteries[index] = lotteries[index+1];
                }
                emit eLog(msg.sender, "removing.....delete111");

                lotteries.length--;
                emit eLog(msg.sender, "removing.....delete222");

                // delete lotteries[i]; DONT need if running above...
                emit eLog(msg.sender, "removing.....deleted, re-check lotteries[]");

            }
        }
    }


    function getLotteries() public view returns (Lottery[]) {
        return lotteries;
    }
    function getNewLotteryAddress() public view returns (address) {
        return newLotteryAddress;
    }
    function getLotteryMaxPlayers() public view returns (uint) {
        Lottery lottery = Lottery(newLotteryAddress); 
        return lottery.getMaxPlayers();
    }
    function getOwner() public view returns (address){
        return owner;
    }
}

// DEV OBSERVATIONS
// 1 Master getLottery 2 addPlayer() <-- would have to pay gas twice? because two transactions?
// 1 Master addPlayer(lotteryAddress) and Contract addPlayer(msg.sender)
// HOWEVER this would allow for 1 smart contract call, instead of 2.
// * dont need this because If you already have lottery address, then don't bother going through Master Contract *
// function addPlayer(address lotteryAddress) public payable {
    // lotteryAddress.activePlayers.push(msg.sender) // won't send ether to it
    // lotteryAddress.addPlayer(msg.sender);
    // lotteryAddress.send(msg.value);
    // or
    // Lottery lottery = Lottery(lotteryAddress)
    //lottery.addActivePlayer(msg.sender);        
    // repeat...
// }

// Need function for updating owner to new owner, only callable by the current owner
// modifier onlyOwner() {
//     if (msg.sender == owner) {
//         _;
//     }
// }
// getMaxPlayers returns { [String: '5'] s: 1, e: 0, c: [ 5 ] }