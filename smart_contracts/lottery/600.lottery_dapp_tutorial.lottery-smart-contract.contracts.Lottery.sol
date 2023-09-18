pragma solidity >=0.4.21 <0.6.0;

contract Lottery {

    struct BetInfo {
        uint256 answerBlockNumber;
        address payable bettor;
        byte challenges; //0xab
    }
    //simple queue
    uint256 private _tail;
    uint256 private _head;
    mapping (uint256 => BetInfo) private _bets;

    address payable public owner;

    uint256 constant internal BLOCK_LIMIT = 256;
    //blockhash(uint blockNumber) returns (bytes32): blockNumber에 해당하는 블록 해시, 최근 256개까지 조회 가능. 현재 블록은 제외 (지금 블록이 만들어지는 중이기 때문에 당연히..)
    uint256 constant internal BET_BLOCK_INTERVAL = 3;
    uint256 constant internal BET_AMOUNT = 5 * 10 ** 15; //0.005 ETH
    uint256 private _pot;
    bool private mode = false;  //false: use answer for test, true: use real block hash
    bytes32 public answerForTest;

    enum BlockStatus {Checkable, NotReavealed, BlockLimitPassed}
    enum BettingResult {Fail, Win, Draw}

    event BET(uint256 index, address bettor, uint256 amount, byte challenges, uint256 answerBlockNumber);
    event WIN(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event FAIL(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event DRAW(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event REFUND(uint256 index, address bettor, uint256 amount, byte challenges, uint256 answerBlockNumber);


    constructor() public {  //deploy 할 때 가장 먼저 실행되는 함수
        owner = msg.sender;
    }

    function getPot() public view returns (uint256 pot) {
        return _pot;
    }

    /**
     * @dev 배팅과 정답 체크를 한다. 유저는 0.005 ETH를 보내야 하고, 베팅용 1 byte 글자를 보낸다.
     * 큐에 저장된 베팅 정보는 이후 distribute 함수에서 해결된다.
     * @param challenges 유저가 베팅하는 글자
     * @return 함수가 잘 수행되었는지 확인하는 bool 값
     */
    function betAndDistribute(byte challenges) public payable returns (bool result) {
        bet (challenges);

        distribute();

        return true;
    }

    /**
     * @dev 배팅을 한다. 유저는 0.005 ETH를 보내야 하고, 베팅용 1 byte 글자를 보낸다.
     * 큐에 저장된 베팅 정보는 이후 distribute 함수에서 해결된다.
     * @param challenges 유저가 베팅하는 글자
     * @return 함수가 잘 수행되었는지 확인하는 bool 값
     */
    function bet (byte challenges) public payable returns (bool result) {
        // check the proper ether is sent
        require(msg.value == BET_AMOUNT, "Not enough ETH");
        // push bet to the queue
        require(pushBet(challenges), "Fail to add a new Bet Info");

        // emit event (event log는 따로 모아서 관리할 수 있음. web3의 filter를 이용하여 외부에서 보이게 할 수도 있음)
        emit BET(_tail - 1, msg.sender, msg.value, challenges, block.number + BET_BLOCK_INTERVAL);
        //event 값을 내보낼 때 gas 소비 많음: emit 연산 자체 375 + 파라미터 한 개 당 375 + 파라미터 값이 저장될 때 바이트 당 8 gas 소비 => 약 5000 gas 소비

        return true;

    }
        //save the bet to the queue
        
    /**
     * @dev 베팅 결과값을 확인하고 팟머니를 분배한다.
     * 정답 실패: 팟머니 축적, 정답 맞춤: 팟머니 획득, 확인 불가 or 한 글자 맞춤: 베팅 금액만 획득
     */

    function distribute() public {
        uint256 cur;
        uint256 transferAmount;
        BetInfo memory b;
        BlockStatus currentBlockStatus;
        BettingResult currentBettingResult;

        for (cur = _head; cur < _tail; cur++) {
            b = _bets[cur];
            currentBlockStatus = getBlockStatus(b.answerBlockNumber);

            // Checkable : block.number > answerBlockNumber && block.number < BLOCK_LIMIT + answerBlockNumber (rtn 1)
            if(currentBlockStatus == BlockStatus.Checkable) {
                bytes32 answerBlockHash = getAnswerBlockHash(b.answerBlockNumber);

                currentBettingResult = isMatch (b.challenges, answerBlockHash);
                // if win, bettor gets pot
                if(currentBettingResult == BettingResult.Win) {
                    // transfer pot
                    transferAmount = transferAfterPayingFee(b.bettor, _pot + BET_AMOUNT);
                    // pot = 0
                    _pot = 0;
                    // emit event (WIN)
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

            // Not Revealed : block.number <= answerBlockNumber (rtn 2)
            if(currentBlockStatus == BlockStatus.NotReavealed) {
                break;
            }

            // Block Limit Passed : block.number >= answerBlockNumber + BLOCK_LIMIT (rtn 3)
            if(currentBlockStatus == BlockStatus.BlockLimitPassed) {
                // refund
                transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);

                // emit refund event
                emit REFUND(cur, b.bettor, transferAmount, b.challenges, b.answerBlockNumber);
            }
            popBet(cur);

            // check the answer

        }
        _head = cur;
    }

    function transferAfterPayingFee (address payable addr, uint256 amount) internal returns (uint256) {
        // uint256 fee = amount / 100;
        uint256 fee = 0;
        uint256 amountWithoutFee = amount - fee;

        // transfer to addr
        addr.transfer(amountWithoutFee);

        // transfer to owner
        owner.transfer(fee);

        // call, send, transfer (methods to send ether)
            // transfer: if it works fail, smart contract is avort (safe)
            // send: if it works fail, smart contract return false (need exception)
            // call: function call + send ether (can call contract externally)


        return amountWithoutFee;
    }

    function setAnswerForTest (bytes32 answer) public returns (bool result) {
        require(msg.sender == owner, "Only owner can set the answer for test mode");
        answerForTest = answer;
        return true;

    }

    function getAnswerBlockHash (uint256 answerBlockNumber) internal view returns (bytes32 answer) {
    // 상태 제어자 (view/pure)
    // view: 컨트랙트 외부에서 call되었을 때 gas를 소모하지 않고 상태 변화가 없는 함수 => 이 함수는 데이터를 보기만 하고 변경하지 않는다
    // pure: gas를 소모하지 않음. 어떤 데이터도 블록체인에 저장하지 않고, 어떤 데이터도 읽지 않는 함수
        return mode ? blockhash(answerBlockNumber) : answerForTest;
    }

    /**
     * @dev 베팅글자와 정답을 확인한다.
     * @param challenges 베팅 글자
     * @param answer 블록 해시
     * @return 정답결과
     */
    function isMatch (byte challenges, bytes32 answer) public pure returns (BettingResult) {
        // challenges 0xab byte
        // answer 0xab.......ff 32 bytes

        byte c1 = challenges;
        byte c2 = challenges;

        byte a1 = answer[0];
        byte a2 = answer[0];

        // Get first number (shift 연산하는 법?)

        c1 = c1 >> 4;   //0xab -> 0x0a
        // 1010 1011 >> 4 = 0000 1010

        c1 = c1 << 4;   //0x0a -> 0xa0
        // 0000 1010 << 4 = 1010 0000

        a1 = a1 >> 4;
        a1 = a1 << 4;

        // Get second number
        c2 = c2 << 4;   // 0xab -> 0xb0
        c2 = c2 >> 4;   // 0xb0 -> 0x0b

        a2 = a2 << 4;
        a2 = a2 >> 4;

        if (a1 == c1 && a2 == c2) {     //
            return BettingResult.Win;
        }

        if (a1 == c1 || a2 == c2) {
            return BettingResult.Draw;
        }

        return BettingResult.Fail;
    }

    function getBlockStatus(uint256 answerBlockNumber) internal view returns(BlockStatus) {
        if(block.number > answerBlockNumber && block.number < BLOCK_LIMIT + answerBlockNumber) {
            return BlockStatus.Checkable;
        }

        if (block.number <= answerBlockNumber) {
            return BlockStatus.NotReavealed;
        }

        if (block.number >= answerBlockNumber + BLOCK_LIMIT) {
            return BlockStatus.BlockLimitPassed;
        }

        return BlockStatus.BlockLimitPassed;

    }

    function getBetInfo (uint256 index) public view returns (uint256 answerBlockNumber, address bettor, byte challenges) {
        BetInfo memory b = _bets[index];
        answerBlockNumber = b.answerBlockNumber;
        bettor = b.bettor;
        challenges = b.challenges;
    }

    function pushBet (byte challenges) internal returns (bool) {
        BetInfo memory b;
        b.bettor = msg.sender;  // 20 bytes
        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL;    // 32 btyes block.number:  현재 블록 번호
        b.challenges = challenges;  // byte

        _bets[_tail] = b;   // 포인터 연산 같은..
        _tail++;    // 32 bytes (uint256) 값 변화 => 처음에는 20000 gas가 들지만 값을 바꿀 때는 5000 gas 소요

        return true;
    }

    function popBet (uint256 index) internal returns (bool) {
        delete _bets[index];  //delete: state db에 있는 데이터를 삭제. 사용한 가스를 돌려받음
        return true;
    }
}