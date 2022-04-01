pragma solidity ^0.4.0;

contract Master {
    address public owner;
    Lottery[] public lotteries;
    address public newLotteryAddress;
    
    event eLog (
        address indexed _from,
        string value
    );

    // MASTERCONTRACTOWNER ... ***
    function Master () public payable {
        owner = msg.sender;
    }

    // don't need _etherContribution, use msg.value instead? but what they're declaring should match what they're sending...Design choice...
    // msg.value goes to the new lottery contract because of .value(msg.value), and user's invocation had {value: web3.toWei(1, 'ether')}
    // .addActivePlayer takes in msg.value as a arbitrary number
    function createLottery(uint _etherContribution, uint _maxPlayers) public payable {
        Lottery newLottery = (new Lottery).value(msg.value)(_etherContribution, _maxPlayers, owner); // msg.sender not owner ***
        // delegatecall so can access the msg.sender from Master?
        // delegate call to set msg.sender in Lottery as same addr as msg.sender in MasterContract
        newLottery.addActivePlayer(owner, msg.value); // msg.sender not owner ***
        newLotteryAddress = address(newLottery);
        lotteries.push(newLottery);
    }

    modifier onlyBy {
        uint256 numLotteries = lotteries.length;
        for (uint i = 0; i < numLotteries; i++) {
            Lottery lottery = lotteries[i];
            if (lottery == msg.sender) {
                emit eLog(msg.sender, "modifier - REMOVE the lottery, it was called by right contract, itself");
                _;
            }
        }
        // TODO - revert() won't work, but worked in Lottery.sol. 'throw;' is supposedly deprecated
    }


    // can use a better keyword than public? what if make private? set exclusive access
    // function removeLottery(address _lotteryAddress) onlyBy public payable { // DON'T NEED arg, can use msg.sender instead
    // delete lotteries[i]; changes lotteries[] from ['0x1234'] to ['0x0000]    
    // need payable ot else "Function state mutability can be restricted to pure function removeLottery() public { ^ (Relevant source part starts here and spans across multiple lines)."
    function removeLottery() onlyBy public payable {              
        address lotteryToRemove = msg.sender;
        uint256 numLotteries = lotteries.length;
        for (uint i = 0; i < numLotteries; i++) {
            Lottery lottery = lotteries[i];
            if (lottery == lotteryToRemove) {
                for (uint index = i; index < numLotteries-1; i++){
                    lotteries[index] = lotteries[index+1];
                }
                lotteries.length--;
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


// ORACLIZE - 'is usingOraclize'
// string public result;
// bytes32 public oraclizeID;
// function __callback(bytes32 _oraclizeID, string _result) public {
//     // TODO logger using bytes32 _oraclizeID?
//     emit eLog(msg.sender, msg.sender, "__callback RESULT...");
//     if(msg.sender != oraclize_cbAddress()) revert();
//     result = _result;
// }
contract Lottery {
    uint public etherContribution;
    uint public maxPlayers;
    address owner;
    address[] public activePlayers;
    Master master;
    
    event eLog (
        address indexed _from,
        address indexed player,
        // uint fee, 
        string value
    );

    // MASTERCONTRACTOWNER in 3 places... starting with LotteryConstructor param _masterContractOwner
    function Lottery (uint _etherContribution, uint _maxPlayers, address _owner) public payable { // address sender
        // param to record masterContractOwner's address?
        etherContribution = _etherContribution;
        maxPlayers = _maxPlayers;
        owner = _owner; // TODO - should be sender? not owner of Master. because maybe lottery creator isn't owner of MasterContract
        master = Master(msg.sender); // should be masterAddress?, or the param address_owner??
        // master = Master(masterOwner?)
    }



    /*
    06/08/18 Hold-off https://github.com/thinkocapo/full-stack-fund/pull/29 https://github.com/thinkocapo/full-stack-fund/issues/30 
    oraclizeID = oraclize_query("WolframAlpha", "flip a coin"); // data source and data input string,  URL is defualt. ID of the request, compare it in the __callback
    __callback from oraclize could call the rest of this...
    */
    // Pay Winner - should really happen before house gets paid their fee... winner.transfer(address(this).balance - fee);
    function addActivePlayer(address player, uint etherAmount) public payable {
        if (etherAmount == etherContribution) {
            emit eLog(msg.sender, player, "value equals ether contribution, add player");
            activePlayers.push(player);
        } else {
            // emit eLog(msg.sender, player, "etherAmount sent was not the same as minEther"); // METP, minEther ToPlayWith
            revert();
        }
        if (activePlayers.length == maxPlayers) {
            // 1 Payout House Fee
            uint fee = (address(this).balance * 2) / 100;
            owner.transfer(fee); // emit eLog(msg.sender, player, fee);
            
            // 2 Pay Winner - should really happen before house gets paid their fee...
            uint randomNumber = 1;
            address winner = activePlayers[randomNumber]; // [acct, acct2] so selects acct2
            winner.transfer(address(this).balance);



            // 3 - Call selfdestruct, and remove the lottery from MasterContract's lotteries[]
            emit eLog(msg.sender, player, "the lottery was filled. payout made...self-destructing and removing from Master Contract lotteries[]"); 
            master.removeLottery();
            selfdestruct(address(this)); // https://en.wikiquote.org/wiki/Inspector_Gadget // can't call eLog or anything on the lottery anymore, because it no longer exists
        } else {
            emit eLog(msg.sender, player, "the lottery was not filled yet");
        }
    }

    function getActivePlayers() public view returns (address[]) {
        getMaxPlayers();
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

