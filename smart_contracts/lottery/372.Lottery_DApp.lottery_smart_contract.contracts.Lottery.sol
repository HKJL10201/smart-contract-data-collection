// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Lottery{
    struct BetInfo{
        uint256 answerBlockNumber;
        address payable bettor;
        bytes1 challenges;
    }

    uint256 private _tail;
    uint256 private _head;
    mapping(uint256 => BetInfo) private _bets;

    address payable public owner;

    uint256 private _pot;
    bool private mode = false;  // false: test mode, true: use real block hash
    bytes32 public answerForTest;

    uint256 constant internal BLOCK_LIMIT = 256;
    uint256 constant internal BET_BLOCK_INTERVAL = 3;
    uint256 constant internal BET_AMOUNT = 5 * 10 ** 15;

    enum BettingResult {Fail, Win, Draw}
    enum BlockStatus {Checkable, NotRevealed, BlockLimitPassed}

    event BET(uint256 index, address bettor, uint256 amount, bytes1 challenges, uint256 answerBlockNumber);
    event WIN(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes32 answer, uint256 answerBlockNumber);
    event FAIL(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes32 answer, uint256 answerBlockNumber);
    event DRAW(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes32 answer, uint256 answerBlockNumber);
    event REFUND(uint256 index, address bettor, uint256 amount, bytes1 challenges, uint256 answerBlockNumber);

    constructor() {
        address sender = msg.sender;
        owner = payable(sender);
    }
    function getPot() public view returns (uint256 value) {
        return _pot;
    }

    /**
     * @dev 베팅과 정답 체크
     * @param challenges 유저가 베팅하는 글자
     * @return result 함수가 잘 수행되었는지 확인하는 bool 값
     */
    function betAndDistribute(bytes1 challenges) public payable returns(bool result){
        bet(challenges);

        distribute();

        return true;
    }

    /**
     * @dev 베팅을 한다. 유저는 0.005 ETH를 보내야하고, 베팅용 1 byte 글자를 보낸다.
     * 큐에 저장된 베팅 정보는 이후 distribute 함수에서 해결된다.
     * @param challenges 유저가 베팅하는 글자
     * @return result 함수가 잘 수행되었는지 확인하는 bool 값
     */
    function bet(bytes1 challenges) public payable returns (bool result){
        // check the proper ether is sent
        require(msg.value == BET_AMOUNT, "Not enough ETH");

        // push bet to the queue
        require(pushBet(challenges), "Fail to add a new Bet Info");

        // emit event
        emit BET(_tail - 1, msg.sender, msg.value, challenges, block.number + BET_BLOCK_INTERVAL);
    }
    // - save the bet to the queue


    /**
     * @dev 베팅 결과값을 확읺 하고 팟머니를 분배
     * 정답 실패: 팟머니 축척, 정답 성공: 팟머니 획득, 한글자 맞춤 or 정답확인 불가: 베팅 금액만 획득
     */
    function distribute() public {
        // head 3 4 5 6 7 8 9 10 11 tail
        // 3번 값을 확인 해보고 정답이면 돈 지급
        // 아니라면 pot 머니에 저장
        // 너무 밀려서 3 ... 286 이라면 돈 리턴
        uint256 cur;
        uint256 transferAmount;

        BetInfo memory b;
        BlockStatus currentBlockStatus;
        BettingResult currentBettingResult;
        for(cur=_head; cur < _tail; cur++){
            b = _bets[cur];
            currentBlockStatus = getBLockStatus(b.answerBlockNumber);

            // Checkable : block.number > AnswerBlockNumber && block.number < BLOCK_LIMIT + AnswerBlockNumber
            if(currentBlockStatus == BlockStatus.Checkable){
                bytes32 answerBlockHash = getAnswerBlockHash(b.answerBlockNumber);
                currentBettingResult = isMatch(b.challenges, answerBlockHash);

                // if win, bettor's gets pot
                if(currentBettingResult == BettingResult.Win){
                    // transfer pot
                    transferAmount = transferAfterPayingFee(b.bettor, _pot + BET_AMOUNT);

                    // pot = 0
                    _pot = 0;

                    // emit WIN
                    emit WIN(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
                // if Fail, bettor's gets pot
                if(currentBettingResult == BettingResult.Fail){
                    // pot = pot * BET_AMOUNT
                    _pot += BET_AMOUNT;

                    // emit FAIL
                    emit FAIL(cur, b.bettor, 0, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
                // if draw, refund bettor's money
                if(currentBettingResult == BettingResult.Draw){
                    // transfer only BET_AMOUNT
                    transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);

                    // emit DRAW
                    emit DRAW(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
            }

            // Not Revealed : block.number <= AnswerBlockNumber
            if(currentBlockStatus == BlockStatus.NotRevealed){
                break;
            }

            // Block Limit Passed: block.number >= AnswerBlockNumber + BLOCK_LIMIT
            if(currentBlockStatus == BlockStatus.BlockLimitPassed) {
                // refund
                transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);
                // emit
                emit REFUND(cur, b.bettor, transferAmount, b.challenges, b.answerBlockNumber);
            }
            popBet(cur);
        }
        _head = cur;
    }

    function transferAfterPayingFee(address payable addr, uint256 amount) internal returns (uint256){
        // uint256 fee = amount / 100;
        uint256 fee = 0;
        uint256 amountWithoutFee = amount - fee;

        // transfer to addr
        addr.transfer(amountWithoutFee);

        // transfer to owner
        owner.transfer(fee);

        // 스마트 컨트랙트 안에서 이더를 전송하는 3가지 방법
        // call, send, transfer
        // transfer를 많이 사용
        // transfer는 딱 이더만 전송하며 실패시 컨트랙트 자체를 Fail 시켜서 가장 안전!

        return amountWithoutFee;
    }
    
    function setAnswerForTest(bytes32 answer) public returns (bool result){
        require(msg.sender == owner, "Only owner can set the answer for test mode");
        answerForTest = answer;
        return true;
    }

    function getAnswerBlockHash(uint256 answerBlockNumber) internal view returns (bytes32 answer){
        return mode ? blockhash(answerBlockNumber) : answerForTest;
    }

    /**
     * @dev 베팅글자와 정답을 확인.
     * @param challenges 베팅 글자
     * @param answer 블락해쉬
     * @return 정답 결과
     */
    function isMatch(bytes1 challenges, bytes32 answer) public pure returns (BettingResult){
        //challenges 0xab
        // answer 0xab........ff 32 bytes

        bytes1 c1 = challenges;
        bytes1 c2 = challenges;

        bytes1 a1 = answer[0];
        bytes1 a2 = answer[0];

        // Get first number
        c1 = c1 >> 4;   // 0xab => 0x0a
        c1 = c1 << 4;   // 0x0a => 0xa0

        a1 = a1 >> 4;
        a1 = a1 << 4;

        // Get Second number
        c2 = c2 << 4;   // 0xab => 0xb0
        c2 = c2 >> 4;   // 0xb0 => oxab

        a2 = a2 << 4;
        a2 = a2 >> 4;

        if(a1 == c1 && a2 == c2){
            return BettingResult.Win;
        }

        if(a1 == c1 || a2 == c2){
            return BettingResult.Draw;
        }

        return BettingResult.Fail;
    }
    
    function getBLockStatus(uint256 answerBlockNumber) internal view returns (BlockStatus) {
        if(block.number > answerBlockNumber && block.number < BLOCK_LIMIT + answerBlockNumber)
            return BlockStatus.Checkable;

        if(block.number <= answerBlockNumber)
            return BlockStatus.NotRevealed;

        if(block.number >= answerBlockNumber + BLOCK_LIMIT)
            return BlockStatus.BlockLimitPassed;

        return BlockStatus.BlockLimitPassed;
    }

    function getBetInfo(uint256 index) public view returns (uint256 answerBlockNumber, address bettor, bytes1 challenges){
        BetInfo memory b = _bets[index];
        answerBlockNumber = b.answerBlockNumber;
        bettor = b.bettor;
        challenges = b.challenges;
    }

    function pushBet(bytes1 challenges) internal returns (bool){
        BetInfo memory b;
        b.bettor = payable(msg.sender);
        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL;
        b.challenges = challenges;

        _bets[_tail] = b;
        _tail++;

        return true;
    }

    function popBet(uint256 index) internal returns (bool){
        // delete하면 데이터를 저장하지 않겠다는 의미로 일정량의 가스비를 돌려받음
        delete _bets[index];
        return true;
    }
}