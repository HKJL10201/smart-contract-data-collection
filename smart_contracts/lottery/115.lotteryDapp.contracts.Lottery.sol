// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


contract Lottery {
    struct BetInfo {
        uint256 answerBlockNumber; 
        address payable bettor;
        bytes1 challenges;  // 0xab, byte 없어져서 수정
    }

    uint256 private _tail;
    uint256 private _head;
    mapping (uint256 => BetInfo) private _bets;

    address payable public owner;
    bool private mode = false;  // false : test mode (use answer for test), true : real mode (use real block hash)
    bytes32 public answerForTest;

    uint256 constant internal BLOCK_LIMIT = 256;
    uint256 constant internal BET_BLOCK_INTERVAL = 3;
    uint256 constant internal BET_AMOUNT = 5 * 10 ** 15;  // 베팅 금액 고정

    uint256 private _pot;  // 팟 머니 저장

    enum BlockStatus {Checkable, NotRevealed, BlockLimitPassed}
    enum BettingResult {Fail, Win, Draw}

    event BET(uint256 index, address bettor, uint256 amount, bytes1 challenges, uint256 answerBlockNumber);
    event WIN(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 annswerBlockNumber);
    event FAIL(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 annswerBlockNumber);
    event DRAW(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 annswerBlockNumber);
    event REFUND(uint256 index, address bettor, uint256 amount, bytes1 challenges, uint256 annswerBlockNumber);
    
    constructor() {
        owner = payable(msg.sender);  // 23.02.12 수정
    }

    // _pot 값 조회
    function getPot() public view returns (uint256 pot) {
        return _pot;
    }

    /**
     * @dev 베팅과 정답 체크를 함. 유저는 0.005 ETH를 보내야 하고, 베팅용 1byte 글자를 보낸다.
     * 큐에 저장된 베팅 정보는 이후 distribute 함수에서 해결된다.
     * @param challenges 유저가 베팅하는 글자
     * @return result 함수가 잘 수행되었는지 확인
     */
    function betAndDistribute(bytes1 challenges) public payable returns (bool result) {
        bet(challenges);

        distribute();

        return true;
    }

    /**
     * @dev 베팅을 한다. 유저는 0.005 ETH를 보내야 하고, 베팅용 1byte 글자를 보낸다.
     * 큐에 저장된 베팅 정보는 이후 distribute 함수에서 해결된다.
     * @param challenges 유저가 베팅하는 글자
     * @return result 함수가 잘 수행되었는지 확인
     */
    function bet(bytes1 challenges) public payable returns (bool result) {
        // 돈이 제대로 들어왔는지 확인
        require(msg.value == BET_AMOUNT, "Not enough ETH");

        // 큐에 bet 정보 넣기
        require(pushBet(challenges), "Fail to add a new Bet Info");

        // emit event
        emit BET(_tail - 1, msg.sender, msg.value, challenges, block.number + BET_BLOCK_INTERVAL);

        return true;
    }

    /**
     * @dev 베팅 결과값을 확인하고 팟머니를 분배함
     * 정답 실패 : 팟머니 축적
     * 정답 맞춤 : 팟머니 획듯
     * 한글자 맞출 or 정답 확인 불가 : 베팅 금액만 획득
     */
    function distribute() public {
        uint256 cur;
        uint256 transferAmount;

        BetInfo memory b;
        BlockStatus currentBlockStatus;
        BettingResult currentBettingResult;

        for(cur=_head; cur<_tail; cur++) {
            b = _bets[cur];
            currentBlockStatus = getBlockStatus(b.answerBlockNumber);

            // Checkable 
            if(currentBlockStatus == BlockStatus.Checkable) {
                bytes32 answerBlockHash = getAnswerBlockHash(b.answerBlockNumber);
                currentBettingResult = isMatch(b.challenges, answerBlockHash);

                // if win, bettor gets pot
                if(currentBettingResult == BettingResult.Win) {
                    // transfer pot
                    transferAmount = transferAfterPayingFee(b.bettor, _pot + BET_AMOUNT);

                    // pot = 0
                    _pot = 0;

                    // emit WIN
                    emit WIN(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }

                // if fail, bettor's money goes pot
                if(currentBettingResult == BettingResult.Fail) {
                    // pot = pot + BET_AMOUNT
                    _pot += BET_AMOUNT;

                    // emit FAIL 
                    emit FAIL(cur, b.bettor, 0, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }

                // if draw, refund bettor's money 
                if(currentBettingResult == BettingResult.Draw) {
                    // transfer only BET_AMOUNT
                    transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);

                    // emit DRAW
                    emit DRAW(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
            }

            // Not Revealed (마이닝이 안된 상황) 
            if(currentBlockStatus == BlockStatus.NotRevealed) {
                break;
            }

            // Block Limit Passed 
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

    function transferAfterPayingFee(address payable addr, uint256 amount) public returns (uint256) {

        // uint256 fee = amount / 100;
        uint256 fee = 0;
        uint256 amountWithoutFee = amount - fee;

        // transfer to addr
        addr.transfer(amountWithoutFee);

        // transfer to owner
        owner.transfer(fee);

        return amountWithoutFee;
    }

    function setAnswerForTest(bytes32 answer) public returns (bool result) {
        require(msg.sender == owner, "Only owner can set the answer for test mode");
        answerForTest = answer;
        return true;
    }

    function getAnswerBlockHash(uint256 answerBlockNumber) internal view returns (bytes32 answer) {
        return mode ? blockhash(answerBlockNumber) : answerForTest;
    }

    /**
     * @dev 베팅글자와 정답 확인
     * @param challenges 베팅 글자
     * @param answer 블락해쉬
     * @return 정답결과
     */
    function isMatch(bytes1 challenges, bytes32 answer) public pure returns (BettingResult) {
        // challenges 0xab
        // answer 0xab.....ff 32 byte

        bytes1 c1 = challenges;
        bytes1 c2 = challenges;

        bytes1 a1 = answer[0];
        bytes1 a2 = answer[0];

        // Get first number
        c1 = c1 >> 4;  // 0xab -> 0x0a
        c1 = c1 << 4;  // 0x0a -> 0xa0

        a1 = a1 >> 4;
        a1 = a1 << 4;

        // Get second number 
        c2 = c2 << 4;  // 0xab -> 0xb0
        c2 = c2 >> 4;  // 0xb0 -> 0x0b

        a2 = a2 << 4;
        a2 = a2 >> 4;


        // 문자가 모두 같을 경우 
        if(a1 == c1 && a2 == c2) {
            return BettingResult.Win;
        }

        // 하나만 같을 경우
        if(a1 == c1 || a2 == c2) {
            return BettingResult.Draw;
        }

        // 전부 다를 경우
        return BettingResult.Fail;
    }
    
    // block 상태 체크 함수
    function getBlockStatus(uint256 answerBlockNumber) internal view returns(BlockStatus) {
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


    // BetInfo의 값을 가져옴 (큐의 값 (_bets) 가져옴)
    function getBetInfo(uint256 index) public view returns(uint256 answerBlockNumber, address bettor, bytes1 challenges) {
        BetInfo memory b = _bets[index];

        answerBlockNumber = b.answerBlockNumber;
        bettor = b.bettor;
        challenges = b.challenges;
    }

    function pushBet(bytes1 challenges) internal returns(bool) {
        BetInfo memory b;
        b.bettor = payable(msg.sender);  // 수정
        // block.number -> 현재 트랜잭션에 들어가는 블럭의 값을 가져올 수 있음
        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL;
        b.challenges = challenges;

        _bets[_tail] = b;
        _tail++;
        return true;
    }

    function popBet(uint256 index) internal returns(bool) {
        delete _bets[index];
        return true;
    }
}