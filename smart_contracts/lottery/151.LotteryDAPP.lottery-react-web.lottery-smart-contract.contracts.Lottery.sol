pragma solidity >=0.4.21 <0.6.0;

contract Lottery {

    struct BetInfo {
        uint256 answerBlockNumber; // 맞추려는 블록번호
        address payable bettor; // 유저의 계좌(베팅을 한 유저의 계좌) ... 컨트랙트에서 해당 주소에 돈을 보내려면 payable이 명시되어야함
        bytes1 challenges;
    }

    enum BlockStatus { Checkable, NotRevealed, BlockLimitPassed }
    enum BettingResult { Fail, Win, Draw }

    address payable public owner; // public으로 변수선언시 자동적으로 getter를 만들어줌.
    
    bool private mode = false; // false : test mode, true : real mode(using real blockhash)
    bytes32 public answerForTest;

    uint256 constant internal BLOCK_LIMIT = 256;
    uint256 constant internal BET_BLOCK_INTERVAL = 3;
    uint256 constant internal BET_AMOUNT = 5 * (10 ** 15); // 단위는 wei.. 즉 5*10^15 wei = 0.005 Ether

    uint256 private _pot;

    mapping(uint256 => BetInfo) private _bets; // mapping을 활용한 queue 만들기.
    uint256 private _tail; // 다음에 넣어야 할 위치
    uint256 private _head; // 체크해야 할 위치



    // Event Lists  
    event BET(uint256 index, address bettor, uint256 amount, bytes1 challenges, uint256 answerBlockNumber);
    event WIN(uint256 index, address bettor, uint256 amount, bytes1 challenges, byte answer, uint256 answerBlockNumber);
    event FAIL(uint256 index, address bettor, uint256 amount, bytes1 challenges, byte answer, uint256 answerBlockNumber);
    event DRAW(uint256 index, address bettor, uint256 amount, bytes1 challenges, byte answer, uint256 answerBlockNumber);
    event REFUND(uint256 index, address bettor, uint256 amount, bytes1 challenges,  uint256 answerBlockNumber);

    constructor() public {
        owner = msg.sender;
    }


    function getPot() public view returns (uint256 pot) {
        return _pot;
    }


    /**
     * @dev 베팅과 검사를 동시에 한다. (1bet = 0.005 ETH, 베팅용 1byte 글자를 보낸다.)
     * @param challenges 유저가 베팅하고자 하는 글자.
     * @return result 함수가 잘 수행되었는지 확인하는 boolean 값 
     */
    function betAndDistribute(byte challenges) public payable returns (bool result) {
        bet(challenges);
        distribute();

        return true;
    }

    // Bet (베팅) : save the bet to the quere
    /**
     * @dev 유저가 베팅을 한 경우 해당 베팅의 내용을 Queue에 넣는다. (1bet = 0.005 ETH, 베팅용 1byte 글자를 보낸다.)
     * 큐에 저장된 베팅 정보는 이후 distribute 함수에서 해결된다.
     * @param challenges 유저가 베팅하고자 하는 글자.
     * @return result 함수가 잘 수행되었는지 확인하는 boolean 값 
     */
    function bet(bytes1 challenges) public payable returns (bool result) {
        // check the Ether first
        require(msg.value == BET_AMOUNT, "Not enough ETH");
        // push bet to the queue
        require(pushBet(challenges), "Fail to add a new BetInfo");
        // emit event log 
        emit BET(_tail-1, msg.sender, msg.value, challenges, block.number + BET_BLOCK_INTERVAL);
        // 이벤트 사용 이유?
        // web3.js 라이브러리에서 블록체인에 찍힌 특정 이벤트 로그를 모아볼 수 있기 때문이다.
        // event 발생에도 gas가 사용됨. emit : 375gas // parameter 당 375gas // 저장할 때 마다 8gas... 

        return true;
    }



    // Distribute (검증)
    /**
     * @dev 베팅 결과값을 확인하고 팟머니를 분배한다.
     * 정답 실패 : 팟머니 축적, 정답 맞춤 : 팟머니 획득, 한글자 맞춤 또는 정답확인 불가: 베팅 금액만 획득
     */
    function distribute() public {
        // Queue 상황 ] 3 4 5 6 7 8 9 
        //            head           tail
        BetInfo memory b;
        BlockStatus currentBlockStatus;
        BettingResult currentBettingResult;

        uint256 cur;
        uint256 transferAmount;

        for(cur = _head; cur < _tail; cur++) {

            b = _bets[cur];
            currentBlockStatus =  getBlockStatus(b.answerBlockNumber);

            if(currentBlockStatus == BlockStatus.Checkable) {
                bytes32 answerBlockHash = getAnswerBlockHash(b.answerBlockNumber);
                currentBettingResult = isMatch(b.challenges, answerBlockHash);
                if(currentBettingResult == BettingResult.Win) {
                    //transfer pot
                    transferAmount = transferAfterPayingFee(b.bettor, _pot + BET_AMOUNT);
                    //pot is 0
                    _pot = 0;
                    //emit WIN event
                    emit WIN(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
                if(currentBettingResult == BettingResult.Fail) {
                    //pot = pot + 0.005
                    _pot += BET_AMOUNT;
                    //emit FAIL event
                    emit FAIL(cur, b.bettor, 0, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
                if(currentBettingResult == BettingResult.Draw) {
                    //transfer only BET_AMOUNT
                    transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);
                    //emit DRAW event
                    emit DRAW(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
            }
            if(currentBlockStatus == BlockStatus.NotRevealed) {
                break;
            }
            if(currentBlockStatus == BlockStatus.BlockLimitPassed) {
                // refund
                transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);
                // emit refund
                emit REFUND(cur, b.bettor, transferAmount, b.challenges, b.answerBlockNumber);
            }
            // queue remove
            popBet(cur);
        }
        _head = cur;
    }
      // check the answer

    // 수수료 부과 함수
    function transferAfterPayingFee(address payable addr, uint256 amount) internal returns (uint256) {
        uint256 fee = 0; 
        uint256 amountWithoutFee = amount - fee;
        
        //transfer to addr
        addr.transfer(amountWithoutFee);
        //transfer to owner
        owner.transfer(fee);

        // CAUTION
        // ETH 전송 방식: call(function 호출 시 ETH를 같이 전송 가능) -- 보안문제... 쓰지마라!, 
        //               send(실패 시 트랜잭션 거부 X... 단순 false 반환),
        //               transfer(가장 안전)
        return amountWithoutFee;
    }

    function setAnswerForTest(bytes32 answer) public returns (bool result) {
        require(msg.sender == owner, "ONLY owner can set the answer");
        answerForTest = answer;
        return true;
    }

    function getAnswerBlockHash(uint256 answerBlockNumber) internal view returns (bytes32 answer) {
        return mode ? blockhash(answerBlockNumber): answerForTest;
    }




    /**
     * @dev 베팅글자와 정답을 확인 및 비교한다.
     * @param challenges  유저가 베팅한 글자
     * @param answer      실제 블록해시의 값
     * @return 정답결과를 반환한다.  
     */
    function isMatch(bytes1 challenges, bytes32 answer) public pure returns (BettingResult) {
        //challenges : 0x??
        //answer : 0x???????......???? (32bytes)

        byte c1 = challenges; // bytes1 == byte
        byte c2 = challenges;
        byte a1 = answer[0];
        byte a2 = answer[0];


        //SHIFT OPERATION
        // Get First NUM

        c1 = c1 >> 4; // 0xab ==> 0x0a
        c1 = c1 << 4; // 0x0a ==> 0xa0
        a1 = a1 >> 4;
        a1 = a1 << 4;

        // Get Second NUM
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

    function getBlockStatus(uint256 answerBlockNumber) internal view returns (BlockStatus) {
        if(block.number > answerBlockNumber && block.number < BLOCK_LIMIT + answerBlockNumber) {
            return BlockStatus.Checkable;
        }
        if (block.number <= answerBlockNumber ) {
            return BlockStatus.NotRevealed;
        }
        if (block.number >= answerBlockNumber + BLOCK_LIMIT) {
            return BlockStatus.BlockLimitPassed;
        }
        return BlockStatus.BlockLimitPassed;
    }

    function getBetInfo(uint256 index) public view returns (uint256 answerBlockNumber, address bettor, bytes1 challenges) {
        BetInfo memory b = _bets[index];
        answerBlockNumber = b.answerBlockNumber;
        bettor = b.bettor;
        challenges = b.challenges;
    }

    function pushBet(bytes1 challenges) internal returns (bool) {
        BetInfo memory b; 

        b.bettor = msg.sender; //20 bytes (address 용량)
        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL; // 32bytes - 20000
        b.challenges = challenges; // 1byte (20bytes와 합쳐서 20000) (최소 단위가 32bytes이므로...)

        _bets[_tail] = b;
        _tail++; // 32bytes 값 변화 - 20000(처음 변화시 = 이후 5000 gas씩 감소)
 
        return true;

        // 즉, 21000 + 60000 + 기타 연산비용... 
    }

    function popBet(uint256 index) internal returns (bool) {
        delete _bets[index];
        return true;
        // delete를 하면 gas를 돌려받는다!?
    }

    function getETH() public view returns (uint256) {
        return address(this).balance;
    }
}