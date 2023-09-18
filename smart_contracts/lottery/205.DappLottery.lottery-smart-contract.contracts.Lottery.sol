pragma solidity ^0.6.0;
// >=0.4.22 <0.9.0;
contract Lottery {
    struct BetInfo {
        uint256 answerBlockNumber;
        address payable bettor;
        byte challenges;
    }
    uint256 private _tail;
    uint256 private _head;
    mapping (uint256 => BetInfo) private _bets;

    address payable public owner;

    uint256 constant internal BLOCK_LIMIT = 256;
    uint256 constant internal BET_BLOCK_INTERVAL = 3;
    uint256 constant internal BET_AMOUNT = 5 * 10 ** 15;

    uint256 private _pot;
    bool private mode = false; //false : use answer , true : use real block hash
    bytes32 public answerForTest;

    enum BlockStatus {checkable, NotRevealed, BlockLimitPassed}
    enum BettingResult {Fail,Win,Draw}

    event BET(uint256 index, address bettor, uint256 amount, byte challenges, uint256 answerBlockNumber);
    event WIN(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event FAIL(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event DRAW(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event REFUND(uint256 index, address bettor, uint256 amount, byte challenges, uint256 answerBlockNumber);
    constructor() public {
       owner = msg.sender;
    }


    function getPot() public view returns (uint256 pot) {
        return _pot;
    }
    function betAndDistribute(byte challenges) public payable returns (bool result) {
        bet(challenges);
        
        distribute();

        return true;
    }
    // Bet
    /*
        @dev 배팅을 한다. 유저는 0.005이더를 보내야 하고 배팅용 1 바이트 글자를 보낸다.
        큐에 저장된 배팅 정보는 이후 distribute 함수에서 해결된다.
        @param challenges 유저가 배팅하는 글자
        @return 함수가 잘 수행되었는지 확인하는 bool값
     */
    function bet(byte challenges) public payable returns (bool result) {
        // 돈이 제대로 들어왓는지 체크?
        require(msg.value == BET_AMOUNT, "not enough eth");
        // push bet to the queue
        require(pushBet(challenges),"fail to add a new bet info");

        // emit event
        emit BET(_tail - 1, msg.sender, msg.value, challenges, block.number + BET_BLOCK_INTERVAL);

        return true;
    }
     
    // Distribute
       /*
        @dev 배팅 결과값을 확인하고 팟머니를 분배한다.
        정답 실패 : 팟머니 축적, 정답 맞춤: 팟머니 획드, 한글자 맞춤 or 정답 확인 불가 : 배팅 금액만 획득
     */
    function distribute() public{
        uint256 cur;
        uint256 transferAmount;
        BetInfo memory b;
        BlockStatus currentBlockStatus;
        BettingResult currentBettingResult;

        for(cur=_head;cur<_tail;cur++) {
            b = _bets[cur];
            currentBlockStatus = getBlockStatus(b.answerBlockNumber);
            // checkable : block.number > AnswerBlockNumber && block.number < BLOCK_LIMIT + AnswerBlockNumber
            if(currentBlockStatus == BlockStatus.checkable) {
                bytes32 answerBlockHash = getAnswerBlockHash(b.answerBlockNumber);
                currentBettingResult = isMatch(b.challenges, getAnswerBlockHash(b.answerBlockNumber));
                // if win bettor gets pot
                if(currentBettingResult == BettingResult.Win) {
                    // transfer pot
                    transferAmount = transferAfterPayingFee(b.bettor, _pot + BET_AMOUNT);

                    // pot = 0
                    _pot = 0;
                    // emit WIN
                    emit WIN(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);

                }
                // if fail bettor's money goes pot
                if(currentBettingResult == BettingResult.Fail) {
                    // pot = pot + BET_AMOUNT
                    _pot += BET_AMOUNT;
                    // emit FAIL
                    emit FAIL(cur, b.bettor, 0, b.challenges, answerBlockHash[0], b.answerBlockNumber);

                }
                // if draw refund bettor's money
                if(currentBettingResult == BettingResult.Draw) {
                    // transfer only BET_AMOUNT
                     transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);
                    // emit DRAW
                    emit DRAW(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
            }
            // Not revealed : block.number <= AnswerBlockNumber
             if(currentBlockStatus == BlockStatus.NotRevealed) {
                break;
            }
                // block limit passed : block.number >= AnswerBlockNumber + BLOCK_LIMIT
             if(currentBlockStatus == BlockStatus.BlockLimitPassed) {
                // refund
                transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);
                // emit refund
                emit REFUND(cur, b.bettor, transferAmount, b.challenges, b.answerBlockNumber);
            }
            popBet(cur);
        }
        _head = cur;
    }
    function transferAfterPayingFee(address payable addr, uint256 amount) internal returns (uint256) {
        // uint256 fee = amount / 100;
        uint256 fee = 0;
        uint256 amountWithoutFee = amount - fee;

        // ftansfer to addr
        addr.transfer(amountWithoutFee);

        // transfer to owner
        owner.transfer(fee);

        // call, send, transfer 전송3가지
        // 이중 transfer 제일 많이 사용하고 이더만 던져주고 이더를 던진게 실패하면 트랜직션 자체를 feil시킨다.
        // send는 돈을 보내긴 하는데 false 
        // call 이더만 보내는거뿐만 아니라 다른(외부) 스마트컨트랙트 함수를 호출해서 같이 보낼 수 있다.
        // 웹으로 스마트 컨트랙트를 호출 했을때 굉장히 위험하다

        return amountWithoutFee;
    }
    function setAnswerForTest(bytes32 answer) public returns(bool result) {
        require(msg.sender == owner, "only owner can set the answer for test mode ");
        answerForTest = answer;
        return true;
    }
    function getAnswerBlockHash(uint256 answerBlockNumber) internal view returns (bytes32 answer) {
        return mode ? blockhash(answerBlockNumber) : answerForTest;
    }
    /**
        dev 배팅글자와 정답을 확인한다.
        param challenges 배팅글자
        param answer 블록해쉬
        return 정답결과
     */
    function isMatch(byte challenges, bytes32 answer) public pure returns (BettingResult) {
        // challengs 0xab
        // answer 0xab....ff 32byte

        byte c1 = challenges;
        byte c2 = challenges;

        byte a1 = answer[0];
        byte a2 = answer[0];

        c1 = c1 >> 4; //0xab ->0x0a
        c1 = c1 << 4; //0x0a ->0xa0

        // get second number
        c2 = c2 << 4; //0xab ->0xb0
        c2 = c2 >> 4; //0xb0 ->0x0b
        
        a1 = a1 >> 4;
        a1 = a1 << 4;

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
    function getBlockStatus(uint256 answerBlockNumber) internal view returns (BlockStatus) {
        if(block.number > answerBlockNumber && block.number < BLOCK_LIMIT + answerBlockNumber) {
            return BlockStatus.checkable;
        }
        if(block.number <= answerBlockNumber) {
            return BlockStatus.NotRevealed;
        }
        if(block.number >= answerBlockNumber + BLOCK_LIMIT) {
            return BlockStatus.BlockLimitPassed;
        }
        return BlockStatus.BlockLimitPassed;
    }
        

    function getBetInfo(uint256 index) public view returns (uint256 answerBlockNumber, address bettor, byte challenges) {
        BetInfo memory b = _bets[index];
        answerBlockNumber = b.answerBlockNumber;
        bettor = b.bettor;
        challenges = b.challenges;
    }
    function pushBet (byte challenges) internal returns (bool) {
        BetInfo memory b;
        b.bettor = msg.sender;
        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL;
        b.challenges = challenges;

        _bets[_tail] = b;
        _tail++;
        
        return true;
    }

    function popBet(uint256 index) internal returns (bool) {
        delete _bets[index];
        return true;
    }
}
