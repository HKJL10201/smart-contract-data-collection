// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Lottery {

    struct BetInfo { //
        uint256 answerBlockNumber; // 맞추려고 하는 정답 블록
        address payable bettor; // 베터의 주소 *payable 꼭 쓰기 (trasfer를 위해)
        bytes1 challenges; // 베터의 제출 답안
    }

    // _bets 라는 queue로 값이 들어오면 _tail이 증가하면서 계속 값을 넣어주게 된다.
    // 베팅 결과를 검증할 때는 head 부터 차례대로 검증한다.
    mapping (uint256 => BetInfo) private _bets; // BetInfo struct 를 저장하는 queue 이다.
    uint256 private _head;
    uint256 private _tail;

    // bettor 지갑 주소
    address payable public owner;
    
    // 필요한 상수들의 정의
    uint256 constant internal BLOCK_LIMIT = 256; // 블록 해쉬로 확인할 수 있는 제한
    uint256 constant internal BET_BLOCK_INTERVAL = 3; // 3번째 블록해쉬
	// 1 * 10 ** 18 = 1 eth
	uint256 constant internal BET_AMOUNT = 0 * 10 ** 15; // 0.005 eth
    ////

    uint256 private _pot; // 플레이어가 베팅한 금액의 총합 = 팟머니

    bool private mode = false; // false : use answer for test, true : use real block hash
    bytes32 public answerForTest;


    // enum 배열 {0, 1, 2 ...}
    // 1. 체크 가능 2. 생성되지 않음 3. 리밋 지남
    enum BlockStatus {Checkable, NotRevealed, BlockLimitpassed}

    // 1. 실패 2. 승리 3. 무승부
    enum BettingResult {Fail, Win, Draw}

    // 이벤트 로그는 블록체인 function으로 호출 가능
    // 로그들을 따로 모을 수 있다.
    // web3.js 같은 라이브러리에서 특정 로그를 긁어올 수 있다.
    // 몇번째 배팅인지, 베터의 주소, 양, 제출한 정답, 어떤 블록을 맞추려고 하는지
    event BET(uint256 index, address bettor, uint256 amount, bytes1 challenges, uint256 answerBlockNumber);
    event WIN(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event FAIL(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event DRAW(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event REFUND(uint256 index, address bettor, uint256 amount, bytes1 challenges, uint256 answerBlockNumber);

    constructor() public {
        owner = payable(msg.sender);
    }

    // function getSomeValue() public pure returns (uint256 value) {
    //     return 5;
        
    // }

    // 팟 머니를 가져오는 함수
    function getPot() public view returns (uint256 pot) {
        return _pot;
    }

    // 베팅 분배 한번에
    function betAndDistribute(bytes1 challenges) public payable returns (bool result) {
        bet(challenges);

        distribute();

        return true;
    }

    
    // Bet
    // save the bet to the queue
    // 베팅 정보를 큐에 저장

    /**
    * @dev 베팅을 한다. 유저는 0.05 ETH를 보내야 하고, 배팅용 1 byte 글자를 보낸다.
    * 큐에 저장된 배팅 정보는 이후 distribute 함수에서 해결된다.
    * @param challenges 배팅용 1 byte 글자 (유저가 베팅하는 글자)
    * @return result 함수가 잘 수행되었는지 확인하는 bool 값
     */
    function bet(bytes1 challenges) public payable returns (bool result) { // payable 이 들어가지 않으면 돈을 날릴 수 없다.
        // check money is sent
        // 돈이 전송됐는지
        require(msg.value == BET_AMOUNT, "Not enough ETH");

        // push bet to the queue
        // 큐에 넣기
        require(pushBet(challenges), "Fail to add a new Bet Info");

        // emit event
        emit BET(_tail - 1, msg.sender, msg.value, challenges, block.number + BET_BLOCK_INTERVAL);

        return true;

    }

    /**
     * @dev 베팅 결과값을 확인 하고 팟머니를 분배한다.
     * 정답 실패 : 팟머니 축척, 정답 맞춤 : 팟머니 획득, 한글자 맞춤 or 정답 확인 불가 : 베팅 금액만 획득
     */
    //Distribute
    // check the answer
    // 배팅 후 정답 체크 + 상금 분배
    function distribute() public {
        // head 3 4 5 6 7 8 9 10 11 tail <- insert
        // 3번 정답 확인 -> 정답 -> 상금 지급 -> 3번 pop
        // 4, 5, 6 순서대로 확인 -> 아직 블록이 생성되지 않아 정답을 확인할 수 없다면 멈춘다.
        // 정답을 확인할 수 없다면 (256 이상 차이날 때) -> 돈을 그냥 돌려준다.

        // 헤드부터 테일까지 도는 루프
        // 현재 인덱스
        uint256 cur;
        // 전송한 금액
        uint256 transferAmount;
        
        BetInfo memory b;

        // 현재 블록의 상태를 저장 --> enum BlockStatus {Checkable, NotRevealed, BlockLimitpassed}
        BlockStatus currentBlockStatus;

        // 배팅 결과를 저장 --> enum BettingResult {Fail, Win, Draw}
        BettingResult currentBettingResult;


        for(cur = _head; cur < _tail; cur++) {
            b = _bets[cur];
            currentBlockStatus = getBlockStatus(b.answerBlockNumber);
            // Checkable : 체크할 수 있을 때 ----------------------------------------> 1

            // 1. 트랜잭션이 속한 블록 넘버가 정답 블록넘버보다 커야 함  
            // block.number > AnswerBlockNumber
            // 2. 현재 블록 넘버가 (블록 리밋 + 정답 블록 넘버) 보단 안쪽에 있어야 함
            // block.number <= BLOCK_LIMIT + AnswerBlockNumber
            // => AnswerBlockNumber < block.number <= BLOCK_LIMIT + AnswerBlockNumber
            // -----------------------------------------------------------------------------
            if(currentBlockStatus == BlockStatus.Checkable) {

                // block.blockhash(uint blockNumber) returns (bytes32) - 주어진 블록의 해시값을 리턴
                bytes32 answerBlockHash = getAnserBlockHash(b.answerBlockNumber);
                currentBettingResult = isMatch(b.challenges, answerBlockHash);

                // 맞추면 팟머니를 얻는다.
                if ( currentBettingResult == BettingResult.Win) {
                    // 팟 머니 지급
                    transferAmount = transferAfterPayingFee(b.bettor, _pot + BET_AMOUNT);

                    // pot = 0
                    _pot = 0;

                    // emit WIN
                    emit WIN(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }

                // 실패하면 베팅한 돈은 팟머니에 쌓인다.
                if ( currentBettingResult == BettingResult.Fail) {
                    // pot = pot + BET_AMOUNT
                    _pot += BET_AMOUNT;

                    // emit FAIL
                    emit FAIL(cur, b.bettor, 0, b.challenges, answerBlockHash[0], b.answerBlockNumber);


                }
                
                
                // 비기면 베팅 머니를 돌려준다.
                if ( currentBettingResult == BettingResult.Draw) {
                    // 베팅한 돈을 돌려준다
                    transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);

                    // emit DRAW
                    emit DRAW(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);

                }                
            }

            // 체크할 수 없을 때 = 블록 해시를 확인할 수 없을 때

            // 1. 블록이 아직 마이닝 되지 않았을 때 --------------------------------------------> 2
            // 정답 블록보다 현재 블록이 작거나 같음
            // block.number <= AnswerBlockNumber
            if(currentBlockStatus == BlockStatus.NotRevealed) {
                break;
            }


            // 2. 블록 리밋 (256)이 지났을 때 -------------------------------------------------> 3
            // block.number >= BLOCK_LIMIT + AnswerBlockNumber
            if(currentBlockStatus == BlockStatus.BlockLimitpassed) {
                // refund
                transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);


                //emit refund
                emit REFUND(cur, b.bettor, transferAmount, b.challenges, b.answerBlockNumber);

            }

            // -------------------------------------------------------------------------------


            popBet(cur);
        }

        // queue 줄이기
        _head = cur;

    }


    // 특정 주소에게 얼마를 지불, 일정량의 수수료를 떼서 오너에게 전송
    function transferAfterPayingFee(address payable addr, uint256 amount) internal returns (uint256) {
        
        // uint256 fee = amount / 100;
        uint256 fee = 0;
        uint256 amountWithoutFee = amount - fee;

        // transfer to addr
        // 특정 주소에 전송
        addr.transfer(amountWithoutFee);

        // transfer to owner
        // 컨트랙트 배포자에게 전송
        owner.transfer(fee);

        // ether 전송 = call, send, transfer
        // transfer : 이더 전송 실패하면 트랜잭션 취소 = 안전
        // send : 전송이 성공해도 fail 발생 -> 예외처리 가능
        // call : 다른 컨트랙트에 function 호출 가능 -> 함수를 호출하면서 이더 전송 가능

        return amountWithoutFee;
    }

    function setAnswerForTest(bytes32 answer) public returns (bool result) {
        require(msg.sender == owner, "Only owner can set the answer for test mode");
        answerForTest = answer;
        return true;
    }

    // mode : true -> blockhash 값 이용 -> real block hash use
    // mode : false -> 정답으로 지정해준 정답값을 리턴 받아 사용 -> test
    function getAnserBlockHash(uint256 answerBlockNumber) internal view returns (bytes32 answer) {
        return mode ? blockhash(answerBlockNumber) : answerForTest;
    }

    /**
    @dev 베팅글자와 정답을 확인
    @param challenges 베팅 글자
    @param answer 블록 해쉬값
    @return 정답 결과
     */
    function isMatch(bytes1 challenges, bytes32 answer) public pure returns (BettingResult) {
        // challenges = 0xab = 1bytes
        // answer = 0xab...ff = 32bytes

        bytes1 c1 = challenges;
        bytes1 c2 = challenges;

        bytes1 a1 = answer[0];
        bytes1 a2 = answer[0];

        // Get first number
        // shift 연산 4bit shift
        c1 = c1 >> 4; // 0xab -> 0x0a
        c1 = c1 << 4; // 0x0a -> 0xa0

        a1 = a1 >> 4;
        a1 = a1 << 4;

        c2 = c2 << 4; // 0xab -> 0xb0
        c2 = c2 >> 4; // 0xb0 -> 0x0b

        a2 = a2 << 4;
        a2 = a2 >> 4;

        if(a1 == c1 && a2 == c2) {
            return BettingResult.Win;
        }

        if( a1 == c1 || a2 == c2 ) {
            return BettingResult.Draw;
        }
        
        return BettingResult.Fail;
    }

    function getBlockStatus(uint256 answerBlockNumber) internal view returns (BlockStatus) {
        // case 1
        if(block.number > answerBlockNumber && block.number < BLOCK_LIMIT + answerBlockNumber) {
            return BlockStatus.Checkable;
        }

        // case 2
        if(block.number <= answerBlockNumber) {
            return BlockStatus.NotRevealed;
        }

        // case 3
        if(block.number >= BLOCK_LIMIT + answerBlockNumber) {
            return BlockStatus.BlockLimitpassed;
        }
    }


    // 베팅 정보 가져오기
    // view = 보기만 하는 함수
    function getBetInfo(uint256 index) public view returns (uint256 answerBlockNumber, address bettor, bytes1 challenges) {
        BetInfo memory b = _bets[index];
        answerBlockNumber = b.answerBlockNumber;
        bettor = payable(b.bettor);
        challenges = b.challenges;
    }

    // 큐에 원소를 넣음
    function pushBet(bytes1 challenges) internal returns (bool result) {
        
        // BetInfo structure memory 변수 b
        BetInfo memory b;

        b.bettor = payable(msg.sender); // 20 byte

        // block.number = 현재 트랜젝션에 들어가는 블록의 값을 가져올 수 있음
        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL; // 32byte  20000 gas
        b.challenges = challenges; // byte // 20000 gas

        // queue 에 tail index자리에 삽입
        _bets[_tail] = b;
        // tail 값 증가 = length 증가
        _tail++; // 32byte 값 변화 // 20000 gas -> 5000 gas
        return true;
    }

    // 블록체인에 있는 데이터를 삭제하면 일정량의 가스를 돌려받는다.
    function popBet(uint256 index) internal returns (bool) {
        delete _bets[index];
        return true;
    }
}