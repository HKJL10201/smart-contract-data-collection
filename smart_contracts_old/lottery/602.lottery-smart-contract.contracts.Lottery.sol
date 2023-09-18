pragma solidity >=0.4.22 <0.9.0;

contract Lottery {
    struct BetInfo {
        uint256 answerBlockNumber;
        address payable better;
        bytes1 challenges;//byte타입이 지금은 안되므로 bytes1을 사용
    }

    uint256 private _tail;
    uint256 private _head;
    mapping (uint256 => BetInfo) private _bets;

    address payable public  owner;

    bool private mode = false; // false : use answer for test, true : use real block hash
    bytes32 public answerForTest;
    uint256 constant internal BLOCK_LIMIT = 256;
    uint256 constant internal BET_BLOCK_INTERNAL = 3;

    uint256 constant internal BET_AMOUNT = 5*10**15;
    uint256 private _pot;

    enum BlockStatus {Checkable, NotRevealed, BlockLimitPassed}
    enum BettingResult {Fail, Win, Draw}

    event BET(uint256 index, address indexed better, uint amount, bytes1 challenges, uint256 answerBlockNumber);
    event WIN(uint256 index, address better, uint amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event FAIL(uint256 index, address better, uint amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event DRAW(uint256 index, address better, uint amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event REFUND(uint256 index, address better, uint amount, bytes1 challenges, uint256 answerBlockNumber);

    constructor() public {
        owner  = msg.sender;
    }

    function getSomeValue() public pure returns (uint256 value) {
        return 5;
    }

    function getPot() public view returns (uint256 pot) {
        return _pot;
    }

    function betAndDistribute(bytes1 challenges) public payable returns (bool result) {
        bet(challenges);
        distribute();

        return true;
    }
    /**
     * @dev 베팅 결과값을 확인 하고 팟머니를 분배한다.
     * 정답 실패 : 팟이나 축척, 정답 맞춤 : 팟머니 획득, 한글자 맞춤 or 정답 확인 불가 : 베팅 금액만 획득
     */

    function distribute() public  {
        // head 3 ...... 286 287 8 9 10 11 12 tail
        uint256 cur;
        uint256 transferAmount;

        BetInfo memory b;
        BlockStatus currentBlockStatus;
        BettingResult currentBettingResult;

        for(cur=_head; cur < _tail; cur++) {
            b = _bets[cur];
            currentBlockStatus = getBlockStatus(b.answerBlockNumber);
            //Checkable : block.number > AnswerBlockNumber && block.number < BLOCK_LIMIT  + AnswerBlockNumber 1
            if(currentBlockStatus == BlockStatus.Checkable) {
                bytes32 answerBlockHash = getAnswerBlockHash(b.answerBlockNumber);
                currentBettingResult = isMatch(b.challenges, answerBlockHash);

                //if win, better gets pot
                if(currentBettingResult == BettingResult.Win) {
                    //transfer pot
                    transferAmount = transferAfterPayingFee(b.better,_pot+BET_AMOUNT);

                    // pot = 0
                    _pot = 0;

                    emit WIN(cur, b.better, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
                //if fail, better's money goes pot
                if(currentBettingResult == BettingResult.Fail) {
                    //pot = pot + BET_AMOUNT
                    _pot += BET_AMOUNT;
                    //emit DRAW
                    emit DRAW(cur,b.better,transferAmount,b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
            }
            //Not Reavealed : block.number <= AnswerBlockNumber 2
            if(currentBlockStatus == BlockStatus.NotRevealed) {
                break;
            }

            //Block Limit Passed : block.number >= AnswerBlockNumber + BLOCK_LIMIT 3
            if(currentBlockStatus == BlockStatus.BlockLimitPassed) {
                //refund
                transferAmount = transferAfterPayingFee(b.better, BET_AMOUNT);
                //emit refund
                emit REFUND(cur, b.better, transferAmount, b.challenges, b.answerBlockNumber);
            }
            popBet(cur);
        }
        _head = cur;
    }

    function transferAfterPayingFee(address payable addr, uint256 amount) internal returns (uint256) {
        uint256 fee = 0;
        uint256 amountWithoutFee = amount - fee;

        //transfer to addr
        addr.transfer(amountWithoutFee);
        //transfer to owner
        owner.transfer(fee);

        return amountWithoutFee;
    }
    function setAnswerForTest(bytes32 answer) public returns (bool result) {
        require(msg.sender == owner, "Only owner can set the answer for test mode");
        answerForTest = answer;
        return true;
    }
    /**
     * @dev 베팅글자와 정답을 확인한다.
     * @param challenges 베팅 글자
     * @param answer 블락해쉬
     * @return BettingResult 정답결과
     */
    function isMatch(bytes1 challenges, bytes32 answer) public pure returns (BettingResult) {
        //challenges 0xab
        //answer 0xab.........ff 32 bytes

        bytes1 c1 = challenges;
        bytes1 c2 = challenges;

        bytes1 a1 = answer[0];
        bytes1 a2 = answer[0];

        //Get first Number
        c1 = c1 >> 4;// 0xab -> 0x0a
        c1 = c1 << 4;// 0x0a -> 0xa0

        a1 = a1 >> 4;
        a1 = a1 << 4;

        //Get Second Number
        c2 = c2 << 4; // 0xab -> 0xb0
        c2 = c2 >> 4; // 0xb0 -> 0x0b

        a2 = a2 << 4;
        a2 = a2 >> 4;

        if(a1 == c1 && a2 == c2) {
            return BettingResult.Win;
        }

        if(a1 == c1 || a2 == c2) {
            return BettingResult.Draw;
        }

        return BettingResult.Fail;

    }
    function getBlockStatus (uint256 answerBlockNumber) internal view returns (BlockStatus) {
        if(block.number > answerBlockNumber && block.number < BLOCK_LIMIT + answerBlockNumber) {
            return BlockStatus.Checkable;
        }

        if(block.number <= answerBlockNumber) {
            return BlockStatus.NotRevealed;
        }

        if(block.number >= answerBlockNumber + BLOCK_LIMIT) {
            return BlockStatus.BlockLimitPassed;
        }

        return BlockStatus.BlockLimitPassed;
    }

    function getAnswerBlockHash (uint256 answerBlockHash) internal view returns (bytes32 answer) {
        return mode ? blockhash(answerBlockHash) : answerForTest;
    }
    //Bet
    /** 
     * @dev 베팅을 한다. 유저는 0.005eth를 보내야하고, 베팅을 1 byte 글자를 보낸다.
     * 큐에 저장된 베팅 정보는 이후 distribute 함수에서 해결된다.
     * @param challenges 유저가 베팅하는 글자
     * @return result 함수가 잘 수행되었는지 확인하는 bool 값
     */
    function bet(bytes1 challenges) public payable returns (bool result) {
        //check the proper ether is sent
        require(msg.value == BET_AMOUNT, "Not enouth ETH");

        require(pushBet(challenges), "Fail to add a new bet");
        //push bet to the queue

        //emit 
        emit BET(_tail - 1, msg.sender, msg.value, challenges, block.number + BET_BLOCK_INTERNAL);
        return true;
    }
        //save the bet to the queue
    //Distribute
        //check the answer
    function getBetInfo(uint256 index) public view returns (uint256 answerBlockNumber, address better, bytes1 challenges) {
        BetInfo memory b = _bets[index];
        answerBlockNumber = b.answerBlockNumber;
        better = b.better;
        challenges = b.challenges;

    }

    function pushBet(bytes1 challenges) internal returns (bool) {
        BetInfo memory b;
        b.better = msg.sender; //better가 payable 해야하므로 다음과 같이 payable한 주소 할당
        b.answerBlockNumber = block.number + BET_BLOCK_INTERNAL;
        b.challenges = challenges;// byte // 20000 gas
        _bets[_tail] = b;
        _tail++;//32byte 값 변화 // 20000 gas -> 5000 gas

        return true;
    }

    function popBet(uint256 index) internal returns (bool) {
        delete _bets[index];
        return true;
    }
}