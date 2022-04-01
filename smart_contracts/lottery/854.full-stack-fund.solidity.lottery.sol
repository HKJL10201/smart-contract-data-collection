pragma solidity ^0.4.0;
// import "./MasterContract.sol";
// https://ethereum.stackexchange.com/questions/26674/deploying-abstract-contracts-and-interfaces?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa

// addActivePlayer - there was a  param {value: web3.toWei(1, 'ether') } sent when web3 invocated this method...thats how the Lottery Contract gets the eth.
// no need to capture a 'balance' member variable because ether send to Contract Address, which has a native balance
// activePlayers.push(sender); DEPRECATED, because call setter method during createLottery invocation in MasterContract
// msg.sender here is MasterContract if that's where it was invoked from...
// msg.sender here is from {from: address} if method is being invoked directly on lotteryContract (as in adding the 2nd player)
contract Lottery {
    uint public etherContribution;
    uint public maxPlayers;
    address owner;
    address[] public activePlayers;
    address masterContractAddress;
    // MasterContract master;

    event eLog (
        address indexed _from,
        address indexed player,
        string value
    );

    function Lottery (uint _etherContribution, uint _maxPlayers, address _owner) public payable { // address sender
        etherContribution = _etherContribution;
        maxPlayers = _maxPlayers;
        owner = _owner; // TODO - should be sender? not owner of Master. maybe lottery creator isn't owner of MasterContract
        // master = MasterContract(msg.sender);
        // MasterContract master = MasterContract(msg.sender);
        masterContractAddress = msg.sender;
    }

    function addActivePlayer(address player, uint etherAmount) public payable {
        if (etherAmount == etherContribution) {
            emit eLog(msg.sender, player, "value equals ether contribution, add player");
            activePlayers.push(player);
        } else {
            emit eLog(msg.sender, player, "etherAmount sent was not the same as minEther"); // METP, minEther ToPlayWith
        }
        if (activePlayers.length == maxPlayers) {
            // 1 - randomWinner() Winner should receive money successfully before the House takes a Fee
            // ORACLIZE...
            
            uint randomNumber = 1;
            address winner = activePlayers[randomNumber];
            winner.transfer(address(this).balance);
            
            // 2 - payouts()
            //uint numerator = 1;
            //uint denominator = 100;
            //uint fee = (this.balance * numerator) / denominator;
            //owner.transfer(fee); // does this substract it from this.balance??? 
            
            // 3 - remove from MasterContract lotteries[] and selfdestruct() https://en.wikiquote.org/wiki/Inspector_Gadget
            emit eLog(msg.sender, player, "the lottery was filled. payout made...self-destructing"); // this wont run if you call it after selfdestruct, for obvious reason
            // master.removeLottery();
            selfdestruct(address(this)); // doesnt remove the lottery from MasterContract.sol's Lottery[]
            //
        } else {
            emit eLog(msg.sender, player, "the lottery was not filled yet");
        }
    }

    function getActivePlayers() public view returns (address[]) {
        return activePlayers;
    }
    function getEtherContribution() public view returns (uint) {
        return etherContribution;
    }
    function getMaxPlayers() public view returns (uint) {
        return maxPlayers;
    }
    function getOwner() public view returns (address) {
        return owner;
    }
}


// owner.transfer(this.balance); // wrong program flow but worked

// EMIT EXAMPLE
// logs in node.js, not in your local running blockchain log
//  { logIndex: 0,
//   transactionIndex: 0,
//   transactionHash: '0x63dd197bc47e8020622e17359c518546353489cec9eb1c6e9cfbcd0ccfd26a7e',
//   blockHash: '0x5ccd2ef930117cf328676236b5536121857b93ed337c2e60eda860b161c126c2',
//   blockNumber: 3,
//   address: '0x68f40cf3149e96c6db08908a326af12da8e26322',
//   type: 'mined',
//   event: 'eLog',
//   args:
//    { _from: '0x4dc586b4a3cf013e9a09340541bda5f5b509e19d',
//      _value: 'value equals ether contribution, add player' } }