import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

pragma solidity ^0.8.0;

/** 
 * @title Lottery
 * @dev Ether lotery that transfer contract amount to winner
*/  
contract Lottery is  Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public _idPool;

    //list of players registered in lotery
    address payable[] public players;
    
    struct Pool {
        uint256 id;
        uint256 priceTicket;
        uint256 blockNumberEnd;
        uint256 amountToken;
        address winner;
        bool isDone;
    } 
    

    mapping (uint256 => Pool) public poolInfo;
    
    /**
     * @dev deployement
     */ 
    constructor() {
        
    }

    /** 
     * @dev generate new pool lottery
     * @param _priceTicket: prize of ticket
     * @param _blockNumberEnd: block number when pool finnish
     */ 
    function generatePoolLottery(uint256 _priceTicket, uint256 _blockNumberEnd) external onlyOwner {
        //init pool lottery 
        if (_idPool.current() != 0){
            require(poolInfo[_idPool.current()].isDone , "poolData is not expires");
            require(_blockNumberEnd > block.number , "block expires pool must greate than block now");
        }
        require(_priceTicket > 0 , "price Ticket must greater than zero");

        _idPool.increment();
        uint256 poolId = _idPool.current();
        
        poolInfo[poolId].id = poolId;           
        poolInfo[poolId].winner = address(0);           
        poolInfo[poolId].priceTicket = _priceTicket;           
        poolInfo[poolId].blockNumberEnd = _blockNumberEnd;           
        poolInfo[poolId].isDone = false;           
    }
    
    /**
     * @dev buy ticket
     */ 
    function buyTicket() external payable {
        Pool memory poolData = poolInfo[_idPool.current()];
        require(msg.value == poolData.priceTicket , "price must samge price ticket");
        require(poolData.blockNumberEnd > block.number , "pool is expires");
        require(!poolData.isDone, "pool is expires");
        poolInfo[_idPool.current()].amountToken = poolInfo[_idPool.current()].amountToken + poolData.priceTicket;
        players.push(payable(msg.sender));
    }
    
    /**
     * @dev gets the contracts balance
     * @return contract balance
    */ 
    function getBalance() public view onlyOwner returns(uint){
        return address(this).balance;
    }
    
    /**
     * @dev generates random
     * @return random uint
     */ 
    function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    
    /** 
     * @dev picks a winner from the lottery
     */ 
    function pickWinner() public onlyOwner {
        Pool memory poolData = poolInfo[_idPool.current()];

        //makes sure that we have enough players in the lottery  
        require(poolData.blockNumberEnd < block.number , "poolData is not expires");
        require(!poolData.isDone , "poolData is done");
        
        address payable winner;
        //selects the winner with random number
        winner = players[random() % players.length];
        
        //transfers balance to winner
        winner.transfer(getBalance()); //gets money
        
        poolInfo[_idPool.current()].isDone = true;  
        poolInfo[_idPool.current()].winner = winner;           
        _resetLottery(); 
    }
    
    /**
     * @dev resets the lottery
     */ 
    function _resetLottery() internal {
        players = new address payable[](0);
    }

    /**
     * @dev get infor pool current
     * @return pool data
     */ 
    function getInforPoolCurrent() external view returns  (Pool memory) {
        return poolInfo[_idPool.current()];
    }

    /**
     * @dev get history pool
     * @param idpool: id of pool
     */ 
    function getHistoryPool(uint256 idpool) external view returns  (Pool memory) {
        return poolInfo[idpool];
    }

    /**
     * @dev get prize of history pool
     * @param idpool: id of pool
     * @return prize ticket
     */ 
    function getPrizeOfPool(uint256 idpool) external view returns  (uint256) {
        return poolInfo[idpool].priceTicket;
    }

    /**
     * @dev get block end of history pool
     * @param idpool: id of pool
     * @return block Number End
     */ 
    function getBlockEndOfPool(uint256 idpool) external view returns  (uint256) {
        return poolInfo[idpool].blockNumberEnd;
    }

    /**
     * @dev get winner address of history pool
     * @param idpool: id of pool
     */ 
    function getWinnerOfPool(uint256 idpool) external view returns  (address) {
        return poolInfo[idpool].winner;
    }

    /**
     * @dev get status of history pool
     * @param idpool: id of pool
     */ 
    function getStatusOfPool(uint256 idpool) external view returns (bool) {
        return poolInfo[idpool].isDone;
    }

    /**
     * @dev get amount total of pool
     * @param idpool: id of pool
     */ 
    function getInforAmountTokenOfPool(uint256 idpool) external view returns (uint256) {
        return poolInfo[idpool].amountToken;
    }
}