// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Lottery {
    struct BetInfo {
        uint256 answerBlockNumber;
        address payable bettor; // 돈을 내는 주소. 0.4.x버전 이후에서 부터는 돈을 보내기 위해서는 payable이라는 수식어가 필요하다.
        byte challenges; // 문제에 관한 정도
    }

    uint256 private _tail;
    uint256 private _head;
    mapping(uint256 => BetInfo) private _bets;

    address payable public owner;

    uint256 constant internal BLOCK_LIMIT = 256;
    uint256 constant internal BET_BLOCK_INTERVAL = 3;
    uint256 constant internal BET_AMOUNT = 5 * 10 ** 15; // internal: 내부에서만 -> 10 * 15는 0.001

    uint256 private _pot; // 팟머니를 저장
    bool private mode = false; // false: use answer for test / true: use real block hash
    bytes32 public answerForTest;

    enum BlockStatus {Checkable, NotRevealed, BlockLimitPassed}
    enum BettingResult {Fail, Win, Draw}

    event BET(uint256 index, address bettor, uint256 amount, byte challenges, uint256 answerBlockNumber);
    event WIN(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event FAIL(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event DRAW(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event REFUND(uint256 index, address bettor, uint256 amount, byte challenges, uint256 answerBlockNumber);

    constructor() public {
        owner = msg.sender;
    }

    // view: 스마트 컨트랙트에 변수를 조회하는 수식어
    function getPot() public view returns (uint256 pot) {
        return _pot;
    }

    /**
     * @dev 베팅과 정답 확인을 한다. 유저는 0.005 ETH를 보내야 하고, 베팅용 1 byte 글자를 보낸다.
     * 큐에 저장된 베팅 정보는 이후 distribute 함수에서 해결한다.
     * @param challenges 유저가 베팅하는 글자
     * @return 함수가 잘 수행되었는지 확인하는 bool
     */
    function betAndDistribute(byte challenges) public payable returns (bool result) {
        bet(challenges);

        distribute();

        return true;
    }

    /**
     * @dev 베팅을 한다. 유저는 0.005 ETH를 보내야 하고, 베팅용 1 byte 글자를 보낸다.
     * 큐에 저장된 베팅 정보는 이후 distribute 함수에서 해결한다.
     * @param challenges 유저가 베팅하는 글자
     * @return 함수가 잘 수행되었는지 확인하는 bool
     */
    function bet(byte challenges) public payable returns (bool result) {
        // Check the proper ether is sent
        require(msg.value == BET_AMOUNT, "Not enough ETH");

        // Push bet to the queue
        require(pushBet(challenges), "Fail to add a new Bet");

        // Emit event
        emit BET(_tail - 1, msg.sender, msg.value, challenges, block.number + BET_BLOCK_INTERVAL);

        return true;
    }
    

    /**
     * @dev 베팅 결과를 확인하고 팟머니를 분배한다.
     * 정답 실패: 팟머니 축척; 정답 맞춤: 맞머니 획득; 한글자 맞춤 OR 정답 확인 불가: 베팅 금액만 획득;
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

            // Checkable : block.number > AnswerBlockNumber && block.number < BLOCK_LIMIT + AnswerBlockNumber
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

                // if draw, bettor's money
                if(currentBettingResult == BettingResult.Draw) {
                    // pot = pot + BET_AMOUNT
                    transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);

                    // emit DRAW
                    emit DRAW(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
            }

            // Not Revealed: block.number <= AnswerBlockNumber
            if(currentBlockStatus == BlockStatus.NotRevealed) {
                break;
            }

            // Block Limit Passed: bock.number >= AnswerBlockNumber + BLOCK_LIMIT
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
        uint256 fee = 0; // fee for test
        uint256 amountWithoutFree = amount - fee;

        // trensfer to addr
        addr.transfer(amountWithoutFree);

        // transfer to owner
        owner.transfer(fee);

        return amountWithoutFree;
    }

    function setAnswerForTest(bytes32 answer) public returns (bool result) {
        require(msg.sender == owner, "Only owner can set the answer for test mode");
        answerForTest = answer;
        return true;
    }

    function getAnswerBlockHash(uint256 answerBlockNumber) internal view returns (bytes32 answer) {
        return mode? blockhash(answerBlockNumber) : answerForTest;
    }
    /**
     * @dev 베팅글자와 정답을 확인한다.
     * @param challenges 베팅글자
     * @param answer 블락해쉬
     * @return 정답 결과
     */
    function isMatch(byte challenges, bytes32 answer) public pure returns (BettingResult) {
        // challenges 0xab
        // answer 0xab..... ff 32bytes

        byte c1 = challenges;
        byte c2 = challenges;
        
        byte a1 = answer[0];
        byte a2 = answer[0];

        // Get first number
        c1 = c1 >> 4; // 0xab -> 0x0a
        c1 = c1 << 4; // 0x0a -> 0x0

        a1 = a1 >> 4;
        a1 = a1 << 4;

        // Get Second number
        c2 = c2 << 4;
        c2 = c2 >> 4;

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

    function pushBet(byte challenges) internal returns(bool) {
        BetInfo memory b;
        b.bettor = msg.sender; // 20byte
        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL; // 32byte
        b.challenges = challenges; // byte

        _bets[_tail] = b;
        _tail++; // 32byte

        return true;
    }

    function popBet(uint index) internal returns (bool) {
        delete _bets[index]; // delete를 하면 가스를 돌려 받는다 => 필요없는 데이터는 지워주는 것이 좋음
        return true;
    }
}