// pragma solidity >=0.4.22 <0.9.0;
pragma solidity ^0.6.0;

contract Lottery {
    struct BetInfo {
        uint256 answerBlockNumber;  // 정답 블록 넘버
        address payable bettor;     // 정답 시 여기로 돈을 보냄
        byte challenges;            // 문제, 0xab....
    }

    // 맵을 이용하여 선형 큐 설계 (다이나믹 리스트 or 큐로 가능)
    uint256 private _tail;
    uint256 private _head;
    mapping (uint256 => BetInfo) private _bets; // 여기로 값이 들어오면 tail이 증가하고, 검증은 head부터 시작
    
    address payable public owner;

    // 상수 정의
    uint256 constant internal BLOCK_LIMIT = 256; // 블록 해쉬 제한
    uint256 constant internal BET_BLOCK_INTERVAL = 3; // +3번째 규칙 추가, 유저가 던진 트랜잭션이 들어가는 블록 +3의 블록해쉬
    uint256 constant internal BET_AMOUNT = 5 * 10 ** 15; // 배팅 금액을 0.005 ETH로 고정

    uint256 private _pot; // 팟머니 저장소

    // blockhash()는 랜덤값이기 때문에 테스트에 별로 좋지 않음
    // 그래서 간단한 모드를 만들어 바꿔가면서 테스트 진행
    bool private mode = false; // false: use answer for test
    bytes32 public answerForTest; // true: use real block hash

    // enum
    enum BlockStatus { Checkable, NotRevealed, BlockLimitPassed }
    enum BettingResult { Fail, Win, Draw }

    // event
    event BET(uint256 index, address bettor, uint256 amount, byte challenges, uint256 answerBlockNumber);
    event WIN(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event FAIL(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event DRAW(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event REFUND(uint256 index, address bettor, uint256 amount, byte challenges, uint256 answerBlockNumber);

    constructor() public {
        owner = msg.sender;
    }

    // function getSomeValue() public pure returns(uint256 value) {
    //     return 5;
    // }

    function getPot() public view returns(uint256 pot) {
        return _pot;
    }

    /**
     * @dev 배팅과 정답 체크를 함
     * @param challenges 배팅 시 유저가 보내는 글자
     * return : 함수가 잘 수행되었는지 확인하는 bool값
     */
    function betAndDistribute(byte challenges) public payable returns (bool result) {
        bet(challenges);
        distribute();

        return true;
    }

    /**
     * @dev 배팅 시 유저는 0.005 ETH와 1 byte 크기의 배팅용 글자를 보내야 함
     * @param challenges 배팅 시 유저가 보내는 글자
     * return : 함수가 잘 수행되었는지 확인하는 bool값
     * 큐에 저장 된 배팅 정보는 이후 distribute 함수에서 해결 됨
     */
    // Bet(배팅)
    function bet(byte challenges) public payable returns (bool result) {
        // 돈이 제대로 들어오는지 확인
        require(msg.value == BET_AMOUNT, "Not enough ETH");

        // 배팅 정보를 큐에 저장
        require(pushBet(challenges), "Fail to add a new Bet Info");

        // 이벤트 로그 출력
        emit BET(_tail - 1, msg.sender, msg.value, challenges, block.number + BET_BLOCK_INTERVAL);

        return true;
    }

    /**
     * @dev 배팅 결과값을 확인하고 팟머니를 분배
     * 정답 실패 : 팟머니 축적, 정답 맞춤 : 팟머니 획득, 한글자 맞춤 or 정답 확인 불가 : 배팅 금액만 환불
     */
    // Distribute(검증), 값이 틀리면 팟머니에 저장, 맞으면 돌리는 연산
    function distribute() public {
        // Queue에 저장 된 배팅 정보 -> head 3 4 5 6 7 8 9 10 (새로운 정보는 여기서부터)11 22 tail
        // 언제 멈추는지? 더 이상 정답을 확인 할 수 없을 때(정답 배팅을 한 블록이 아직 채굴되지 않았을 때)
        uint256 cur;
        uint256 transferAmount;
        BetInfo memory b;
        BlockStatus currentBlockStatus;
        BettingResult currentBettingResult;

        for (cur = _head; cur < _tail; cur++) {
            b = _bets[cur];
            currentBlockStatus = getBlockStatus(b.answerBlockNumber); // 현재 블록의 상태
            
            // Checkable, 확인 가능 할 때
            // block.number > answerBlockNumber && block.number < BlOCK_LIMIT + answerBlockNumber
            if (currentBlockStatus == BlockStatus.Checkable) {
                bytes32 answerBlockHash = getAnswerBlockHash(b.answerBlockNumber);
                currentBettingResult = isMatch(b.challenges, answerBlockHash);

                // if win : bettor가 팟머니를 가져감
                if (currentBettingResult == BettingResult.Win) {
                    // 팟머니 이동 후 0으로 초기화
                    transferAmount = transferAfterPayingFee(b.bettor, _pot + BET_AMOUNT);
                    _pot = 0; // transfer가 아닌 call이나 send 사용 시 순서를 위로

                    emit WIN(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
                
                // if fail : bettor의 돈이 팟으로 감
                if (currentBettingResult == BettingResult.Fail) {
                    // 팟머니 + 배팅 금액
                    _pot += BET_AMOUNT;

                    emit FAIL(cur, b.bettor, 0, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }

                // if darw(한글자만 맞췄을 때) : bettor의 돈이 환불이 됨
                if (currentBettingResult == BettingResult.Draw) {
                    // 배팅한 돈만큼 환불
                    transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);

                    emit DRAW(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
            }

            // NotRevealed, 블록 체크가 불가능 할 때(아직 채굴되지 않았을 때)
            // block.number <= answerBlockNumber
            if (currentBlockStatus == BlockStatus.NotRevealed) { 
                break;
            }

            // BlockLimitPassed, 블록 제한이 지났을 때
            // block.number >= answerBlockNumber + BLOCK_LIMIT
            if (currentBlockStatus == BlockStatus.BlockLimitPassed) { 
                // 환불
                transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);

                emit REFUND(cur, b.bettor, transferAmount, b.challenges, b.answerBlockNumber);
            }

            // 정답 체크
            popBet(cur);
        }
        _head = cur; // 헤드 업데이트
    }

    function transferAfterPayingFee(address payable addr, uint256 amount) internal returns (uint256) {
        // uint256 fee = amount / 100; // 수수료
        uint256 fee = 0;
        uint256 amountWithoutFee = amount - fee;

        // transfer to addr
        addr.transfer(amountWithoutFee);

        // transfer to owner
        owner.transfer(fee);

        // 스마트 컨트랙트에서 이더를 전송하는 방법
        // 1: call, 2: send, **3: transfer

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
     * @dev 배팅 글자와 정답을 확인
     * @param challenges 배팅 글자
     * @param answer 블록해쉬
     * return : 정답 결과
     */
    function isMatch(byte challenges, bytes32 answer) public pure returns (BettingResult) {
        // challenges 0xab      // 1 byte
        // answer 0xab....ff    // 32 bytes
        
        // 순서대로 글자를 뽑아서 비교
        byte c1 = challenges;
        byte c2 = challenges;
        
        byte a1 = answer[0];
        byte a2 = answer[0];

        // 첫 번째 숫자 가져오기(시프트 연산)
        c1 = c1 >> 4; // 오른쪽으로 시프팅, 0xab -> 0x0a
        c1 = c1 << 4; // 왼쪽으로 시프팅, 0x0a -> 0xa0

        a1 = a1 >> 4;
        a1 = a1 << 4;

        // 두 번째 숫자 가져오기
        c2 = c2 << 4; // 왼쪽으로 시프팅, 0xab -> 0xb0
        c2 = c2 >> 4; // 오른쪽으로 시프팅, 0xb0 -> 0x0b

        a2 = a2 << 4;
        a2 = a2 >> 4;

        if (a1 == c1 && a2 == c2) {
            return BettingResult.Win;
        }
        if (a1 == c1 || a2 == c2) {
            return BettingResult.Draw;
        }

        return BettingResult.Fail;
    }

    function getBlockStatus(uint256 answerBlockNumber) internal view returns (BlockStatus) {
        if (block.number > answerBlockNumber && block.number < BLOCK_LIMIT + answerBlockNumber) {
            return BlockStatus.Checkable;
        }
        if (block.number <= answerBlockNumber) {
            return BlockStatus.NotRevealed;
        }
        if (block.number >= answerBlockNumber + BLOCK_LIMIT) {
            return BlockStatus.BlockLimitPassed;
        }
        
        return BlockStatus.BlockLimitPassed; // default
    }
    

    function getBetInfo(uint256 index) public view returns(uint256 answerBlockNumber, address bettor, byte challenges) {
        BetInfo memory b = _bets[index]; // 인덱스가 3번까지만 저장되어있더라도 5번에 있는 값을 다 불러 올 수 있고, 다만 그 값들은 0으로 초기화 되어있음
        answerBlockNumber = b.answerBlockNumber;
        bettor = b.bettor;
        challenges = b.challenges;
    }
    function pushBet(byte challenges) internal returns (bool) {
        BetInfo memory b;
        b.bettor = msg.sender;
        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL; // block.number : 현재 이 트랜잭션에 들어가는 블록의 값
        b.challenges = challenges;

        _bets[_tail] = b;
        _tail++; // safemath? integerOverflow?

        return true;
    }
    function popBet(uint256 index) internal returns (bool) {
        // map에 있는 값을 삭제 = 상태 데이터베이스의 값을 삭제
        // 삭제 시 가스를 돌려받음
        delete _bets[index];// 필요하지 않은 값에 대해서는 삭제를 해주는게 좋음
        return true;
    }
}