pragma solidity >=0.4.22 <0.9.0;

contract Lottery {
    struct BetInfo {
        uint256 answerBlockNum; // 32 bytes
        address payable bettor; // 20 bytes
        bytes1 challanges; // 1 bytes
    }
    uint256 private _pot;
    uint256 private _tail; // 32 bytes
    uint256 private _head;
    mapping (uint256 => BetInfo) private _bets; 

    uint256 internal constant BLOCK_LIMIT = 256;
    uint256 internal constant BET_BLOCK_INTERVAL = 3;
    uint256 internal constant BET_AMOUNT = 5 * 10 ** 15;

    enum BlockStatus {Checkable, NotRevealed, BlockLimitPassed}
    enum BettingResult {Win, Draw, Fail}

    bool mode = true; // if false, for test. If not, for real block Hash
    bytes32 blockHashForTest; 

    event BET(uint256 idx, address indexed bettor, uint256 indexed anwserBlockNum, bytes1 challenges);
    event WIN(uint256 idx, address indexed bettor, uint256 indexed anwserBlockNum, bytes1 challenges, bytes32 answer, uint256 amount);
    event FAIL(uint256 idx, address indexed bettor, uint256 indexed anwserBlockNum, bytes1 challenges, bytes32 answer, uint256 amount);
    event DRAW(uint256 idx, address indexed bettor, uint256 indexed anwserBlockNum, bytes1 challenges, bytes32 answer, uint256 amount);
    event REFUND(uint256 idx, address indexed bettor, uint256 indexed anwserBlockNum, bytes1 challenges);

    address payable public owner;

    constructor() public {
        owner = payable(msg.sender);
    }

/**
 * @dev Bet and distribute. 
 */
    function betAndDistribute(bytes1 challenges) public payable {
        bet(challenges);
        distribute();
    }

/**
 * @dev Submit bet transaction. User must send 0.005 ETH and 1 byte string for betting.
        Then, the BetInfo is pushed to the queue (_bet).
        Distribute function process the BetInfo. 
 */
    function bet(bytes1 challenges) public payable returns (bool) {
        require(msg.value == BET_AMOUNT, "[ERROR] Not enough ETH"); // msg.sender.balance >= BET_AMOUNT ?? 
        require(pushBet(challenges), "[ERROR] Fail to add BetInfo");
        emit BET(_tail - 1, msg.sender,block.number + BET_BLOCK_INTERVAL, challenges);
        return true;
    }

/**
 * @dev Check the betting result and distribute the pot money.
        If both letters match, get the pot money (_pot).
        If one letter match or chek is not possible, refund the betting money (BET_AMOUNT).
        If both letters are not matched, accumulate the betting money into the pot money.
 */
    function distribute() public {
        uint256 cur;
        BetInfo memory b;
    
        BlockStatus blockStatus;
        BettingResult bResult;
        
        bytes32 answer;
        uint256 amount;

        for (cur = _head; cur < _tail; cur++) {
            b = _bets[cur];
            blockStatus = getBlockStatus(b.answerBlockNum);
        
            // Check the block of answerBlockNum is revealed
            if (blockStatus == BlockStatus.Checkable) {
                (bResult, answer) = isMatch(b.challanges, getBlockHash(b.answerBlockNum));

                if (bResult == BettingResult.Win) {
                    // Transfer pot and reset pot to 0
                    amount = transferAfterPayingFee(b.bettor, _pot);
                    _pot = 0;
                    emit WIN(cur, b.bettor, b.answerBlockNum, b.challanges, answer, amount);

                } else if (bResult == BettingResult.Fail) {
                    // Update pot = pot + BET_AMOUNT
                    _pot +=  BET_AMOUNT;
                    emit FAIL(cur, b.bettor, b.answerBlockNum, b.challanges, answer, 0);

                } else if (bResult == BettingResult.Draw) {
                    // transfer only BET_AMOUNT
                    amount = transferAfterPayingFee(b.bettor, BET_AMOUNT);
                    emit DRAW(cur, b.bettor, b.answerBlockNum, b.challanges, answer, amount);
                }
                
            } else if (blockStatus == BlockStatus.NotRevealed) {
                break;

            } else if (blockStatus == BlockStatus.BlockLimitPassed) {
                // transfer only BET_AMOUNT
                amount = transferAfterPayingFee(b.bettor, BET_AMOUNT);
                emit REFUND(cur, b.bettor, b.answerBlockNum, b.challanges);
            }
            popBet(cur);
        }
        _head = cur;
    }

    function transferAfterPayingFee(address payable addr, uint256 amount) public returns (uint256) {
        uint256 fee = 0; // it can be "amount / 100" when the fee is 10% of amount; 
        uint256 amountWithoutFee = amount - fee;
        addr.transfer(amountWithoutFee);
        owner.transfer(fee);
        return amountWithoutFee;
    }

    function getBlockStatus(uint256 answerBlockNum) internal view returns (BlockStatus) {
        if (block.number <= answerBlockNum) {
            return BlockStatus.NotRevealed;
        } 
        if (block.number >= answerBlockNum + BLOCK_LIMIT) {
            return BlockStatus.BlockLimitPassed;
        }
        return BlockStatus.Checkable;
    }

    function isMatch(bytes1 challange, bytes32 answer) public pure returns (BettingResult, bytes32) {
        bytes1 c1 = challange;
        bytes1 c2 = challange;
        bytes1 a1 = answer[0];
        bytes1 a2 = answer[0];

        // Get fisrt letter
        c1 = c1 >> 4; // 0xab -> 0x0a
        c1 = c1 << 4; // 0x0a -> 0xa0

        a1 = a1 >> 4;
        a1 = a1 << 4;

        // Get second letter 
        c2 = c2 << 4;
        c2 = c2 >> 4;

        a2 = a2 << 4;
        a2 = a2 >> 4;

        bool fisrtResult = (c1 == a1);
        bool secondResult = (c2 == a2);

        if (fisrtResult && secondResult) {
            return (BettingResult.Win, answer[0]);
        } else if (fisrtResult || secondResult) {
            return (BettingResult.Draw, answer[0]);
        }
        return (BettingResult.Fail, answer[0]);
    }

    function setBlockHashForTest(bytes32 blockHash) public {
        require(msg.sender == owner);
        blockHashForTest = blockHash;
    }

    function getBlockHash(uint256 blockNumber) internal view returns (bytes32) {
        // During testing, blockhash() function can return random values. 
        // So when the mode is "test", it returns the blockHash value set for testing.
        return mode ? blockhash(blockNumber) : blockHashForTest;
    }

    function getPot() public view returns (uint256) {
        return _pot;
    }

    function getBetInfo(uint256 idx) public view returns (uint256 answerBlockNum, address bettor, bytes1 challanges) {
        BetInfo memory b = _bets[idx];
        answerBlockNum = b.answerBlockNum;
        bettor = b.bettor;
        challanges = b.challanges;
    }

    function pushBet(bytes1 challenges) internal returns (bool) {
        _bets[_tail] = BetInfo(block.number + BET_BLOCK_INTERVAL, payable(msg.sender), challenges);
        _tail++;
        return true;
    }

    function popBet(uint256 idx) internal returns (bool) {
        delete _bets[idx];
        return true;
    }
}
