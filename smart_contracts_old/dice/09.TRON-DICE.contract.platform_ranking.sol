pragma solidity ^0.4.25;


interface RankingIF {
    function ranking(address user, uint amount) external payable;
}

contract Test {

    address public rankCtx;

    function setRankingIF(address addr) public {
        rankCtx = addr;
    }

    function ranking() public payable {
        RankingIF(rankCtx).ranking.value(msg.value)(msg.sender, msg.value);
    }
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() external {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
}

contract Ranking is Ownable,RankingIF{
    
    using SafeMath for uint;
    
    address public developer;
    modifier onlyDev() {
        require(msg.sender == developer);
        _;
    }
    function setDev(address _dev) public onlyOwner {
        developer = _dev;
    }

    constructor() public {
        developer = msg.sender;
    }


    uint public gameID;
    struct GameInfo {
        uint amount;
        uint count;
        uint income;
        uint id;
        bool ok;
    }
    mapping(address => GameInfo) gameInfo;
    mapping(uint => address) id2game;

    function setGame(address game, bool ok) public onlyOwner {
        GameInfo storage info = gameInfo[game];
        info.ok = ok;
        if (info.id == 0) {
            gameID++;
            info.id = gameID;
            id2game[gameID] = game;
        }
    }
    uint public income;
    modifier onlyGame {
        if (gameInfo[msg.sender].ok) {
            _;
        } else {
            income = income.add(msg.value);
        }
    }

    /// update rankData
    uint public leaderboard;
    function ranking(address player, uint value) external payable onlyGame {
        
        if (msg.value<=0){
            return;
        }
        
        incUserRank(player, value);
        leaderboard = leaderboard.add(msg.value);
        
        return;
    }
    /// end

    /// Ranking
    event RankStart(uint);
    event RankPrize(address, uint, uint, uint);
  
    /// RankData
    struct RankData {
        uint start;             // start time
        uint end;               // end time
        uint totalPrize;        // total prize of this rank
        address[] id2user;      // userID - 1 => address
        
        address[] rankResult;   // rank result, filled by dev after rank end
        uint[] rankPrize;       // rank prize
        

        mapping (address => uint) user2id;  // address => userID
        mapping (uint => uint) pays;        // userID => dice play sum in this rank
    }
    
    // uint[] rankPrizeRate = [35, 20, 15, 10, 7, 4, 3, 2, 2, 2];
    
    RankData[] ranks; // rank data
    
    /// set leaderboard
    
    /// start a new rank, end current rank
    function rankStart() public onlyDev {
        if (ranks.length>0) {
            ranks[ranks.length-1].end = block.timestamp;
            ranks[ranks.length-1].totalPrize = leaderboard;
            leaderboard = 0;
        }
        address [] memory a;
        address [] memory b;
        uint [] memory c;
        RankData memory rank = RankData(now, 0, 0, a, b, c);
        
        ranks.push(rank);
        
        emit RankStart(ranks.length);
    }
    
    function incUserRank(address _addr, uint _amount) internal {
        if (ranks.length == 0) {
            return;
        }
        
        RankData storage rank = ranks[ranks.length-1];
        
        uint uid = rank.user2id[_addr];
        if (0 == uid) {
            rank.id2user.push(_addr);
            uid = rank.id2user.length;
            rank.user2id[_addr] = uid;
        }
        rank.pays[uid] = rank.pays[uid].add(_amount);
        rank.totalPrize = leaderboard;
    }
    
    /// rankID start from 1
    function getCurrentRank() public view returns (uint rankID) {
        return ranks.length;
    }
    
    /// rankID start from 1
    /// start from 1
    function getRankData(uint rankID, uint start, uint end) public view returns (uint, address[] memory, uint[] memory, uint) {
        if (rankID > ranks.length || 0 == rankID) {
            return;
        }
        
        RankData storage rank = ranks[rankID-1];
        
        uint len = rank.id2user.length; // max user id
        if (0 == len) {
            return;
        }
        
        require(start >=1 && start <= end && end.sub(start) <= 100);
        
        if (end >= len) {
            end = len;
            if (start > end) {
                start = end;
            }
        }
        
        address[] memory addrs = new address[](end - start+1);
        uint[] memory pays = new uint[](end - start+1);
        
        uint idx = 0;
        for (uint i = start; i <= end; i++) {
            addrs[idx] = rank.id2user[i-1];
            pays[idx] = rank.pays[i];
            idx++;

        }
        
        return (len, addrs, pays, rank.totalPrize);
    }
  
    /// store rank result
    function setRankResult(uint rankID, address[] rankResult, uint [] rate ) public onlyDev {
        require(rankID < ranks.length && rankID > 0);
        require(rankResult.length <= 10 && rankResult.length == rate.length);

        RankData storage rank = ranks[rankID-1];
        require(0 == rank.rankResult.length);
        
        // uint[] rankPrizeRate = [35, 20, 15, 10, 7, 4, 3, 2, 2, 2];
        
        for (uint i = 0; i < rankResult.length; i++) {
            if (address(0) != rankResult[i]) {
                uint prize = rank.totalPrize * rate[i] / 100;
                rank.rankPrize.push(prize);
                rank.rankResult.push(rankResult[i]);
                rankResult[i].transfer(prize);
                emit RankPrize(rankResult[i], i+1, prize, rankID-1);
            }
        }
    }
    
    /// read rank result
    function getRankResult(uint rankID) public view returns(address[] memory) {
        if (rankID > ranks.length || 0 == rankID) {
            return;
        }
        
        RankData storage rank = ranks[rankID-1];
        if (rank.rankResult.length == 0) {
            return;
        }
        
        address[] memory rankResult = new address[](rank.rankResult.length);
        for (uint i = 0; i < rank.rankResult.length; i++) {
            rankResult[i] = rank.rankResult[i];
        }
        
        return rankResult;
    }

    /// end Ranking
}
