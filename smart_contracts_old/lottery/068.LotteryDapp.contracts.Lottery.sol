// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Lottery {
    struct BetInfo {
        uint256 answerBlockNumber;
        address payable bettor;
        bytes challenges; // 0xab
    }

    //Lottery에서 사용할 자료구조는 queue
    uint256 private _tail;
    uint256 private _head;
    mapping (uint256 => BetInfo) private _bets;
    
    address payable public owner;

    bool private mode = false; // false : test mode (use test answer), true : real mode (use block hash) 
    bytes32 public answerforTest;
    uint256 constant internal BLOCK_LIMIT = 256;
    uint256 constant internal BET_BLOCK_INTERVAL = 3;
    uint256 constant internal BET_AMOUNT = 5 * 10 ** 15;
    uint256 private _pot;

    enum BlockStatus {Checkable, NotRevealed, BlockLimitPassed}
    enum BettingResult {Fail, Win, Draw}

    event BET(uint256 index, address bettor, uint256 amount, bytes challenges, uint256 answerBlockNumber);
    event WIN(uint256 index, address bettor, uint256 amount, bytes challenges, bytes32 answer, uint256 answerBlockNumber);
    event FAIL(uint256 index, address bettor, uint256 amount, bytes challenges, bytes32 answer, uint256 answerBlockNumber);
    event DRAW(uint256 index, address bettor, uint256 amount, bytes challenges, bytes32 answer, uint256 answerBlockNumber);
    event REFUND(uint256 index, address bettor, uint256 amount, bytes challenges, uint256 answerBlockNumber);
    constructor() {
        owner = payable(msg.sender);
    }

    function getPot() public view returns (uint256 pot) {
        return _pot;
    }

    /**
      * @dev 배팅과 동시에 정답 체크를 한다. 유저는 0.005 ETH를 보내야 하고, 배팅용 1byte 글자를 보낸다.
      * @param challenges 유저가 배팅할 1 byte 단어
      * @return result -> 함수가 잘 수행되었는지 확인하는 bool 값
     */
    function betAndDistribute(bytes memory challenges) public payable returns (bool result) {
        bet(challenges);
        
        distribute();

        return true;
    }

    // Bet
    /**
      * @dev 배팅을 한다. 유저는 0.005 ETH를 보내야 하고, 배팅용 1 byte 글자를 보낸다.
      * 큐에 저장된 배팅 정보는 이후 distribute 함수에서 해결한다.
      * @param challenges 유저가 배팅할 1 byte 단어
      * @return result -> 함수가 잘 수행되었는지 확인하는 bool 값
     */
    function bet(bytes memory challenges) public payable returns (bool result) {
        // check the proper ether sent
        // msg.value를 통해 들어온 eth 값을 확인할 수 있다.
        require(msg.value == BET_AMOUNT, "Not exact ETH");
        
        // push bet to the queue
        require(pushBet(challenges), "Fail to push Bet Info");
        // emit event
        emit BET(_tail - 1, msg.sender, msg.value, challenges, block.number + BET_BLOCK_INTERVAL);
        return true;
    }
        // save the bet to the queue

    // Distribute
    // 자동적으로 블록 + 3이 만들어졌을 때 pot을 확인하는 것이 아닌
    // distribute 함수를 실행함으로 betting 내용을 확인한다.
    /**
      * @dev 배팅 결과 값을 확인하고 팟머니를 분배한다. 
      * 정답 실패 : 팟머니 축적, 정답 맞춤 : 팟머니 획득, 한글자 맞춤 or 정답 확인 불가 : 배팅 금액 환불
     */
    function distribute() public {
        // head 3 4 5 6 7 8 9 10 .. 259 tail (최근 256개의 block까지만 확인이 가능하다.)
        uint256 cur;
        uint256 transferAmount;
        BetInfo memory b;
        BlockStatus currentBlockStatus;
        BettingResult currentBettingResult;

        // 당첨을 확인할 수 없는 두가지 경우
        // 1. 블록 생성이 256개가 지나 확인이 불가능한 경우
        // 2. +3 블록 생성이 아직 되지 않은 경우 
        for (cur = _head; cur < _tail; cur++) {
            b = _bets[cur];
            currentBlockStatus = getBlockStatus(b.answerBlockNumber);
            // Cheackable : block.number > AnswerBlockNumber && block.number < BLOCK_LIMIT + AnswerBlockNumber => 1
            
            if (currentBlockStatus == BlockStatus.Checkable) {
                bytes32 answerBlockHash = getAnswerBlockHash(b.answerBlockNumber);
                // check the answer
                currentBettingResult = isMatch(b.challenges, answerBlockHash);
                // if win, bettor gets pot
                if (currentBettingResult == BettingResult.Win) {
                    // transfer pot
                    transferAmount = transferAfterPayingFee(b.bettor, _pot + BET_AMOUNT);
                    
                    // pot = 0
                    _pot = 0;

                    // emit WIN
                    emit WIN(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
                // if fail, bettor's money goes pot
                if (currentBettingResult == BettingResult.Fail) {
                    // pot = pot + BET_AMOUNT
                    _pot += BET_AMOUNT;
                    
                    // emit FAIL
                    emit FAIL(cur, b.bettor, 0, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
                // if draw, refund bettor's money
                if (currentBettingResult == BettingResult.Draw) {
                    // transfer only BET_AMOUNT
                    transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);
                    
                    // emit DRAW
                    emit DRAW(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
            }
            // Not Revealed : block.number <= AnswerBlockNumber => 2
            // 현재 block의 block hash를 알 수 는 없으므로 <= 연산을 사용해주어야 한다.
            if (currentBlockStatus == BlockStatus.NotRevealed) {
                break;
            }
            // Block Limit Passed : block.number >= BLOCK_LIMIT + AnswerBlockNumber => 3
            if (currentBlockStatus == BlockStatus.BlockLimitPassed) {
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

        // transfer to addr
        addr.transfer(amountWithoutFee);

        // transfer to owner
        owner.transfer(fee);

        return amountWithoutFee;
    }


    function setAnswerForTest(bytes32 answer) public returns (bool result) {
        require(msg.sender == owner, "Only owner can set the answer for test mode");
        answerforTest = answer;
        return true;
    }

    // if mode = false, block hash => answerforTest / if mode = true, block hash => blockhash(answerBlockNumber)
    function getAnswerBlockHash(uint256 answerBlockNumber) internal view returns (bytes32 answer) {
        return mode ? blockhash(answerBlockNumber) : answerforTest;
    }

    /**
      * @dev 배팅 글자의 정답을 확인한다.
      * @param challenges 배탕 글자
      * @param answer 정답 글자
      * @return 정답 결과
     */
    function isMatch(bytes memory challenges, bytes32 answer) public pure returns (BettingResult) {
        // challenges 0xab
        // answer 0xab......ff 32 bytes
        bytes1 c1 = challenges[0];
        bytes1 c2 = challenges[0];
        bytes1 a1 = answer[0];
        bytes1 a2 = answer[0];

        // Get first number
        c1 = c1 >> 4; // 0xab -> 0x0a
        c1 = c1 << 4; // 0x0a -> 0xa0

        a1 = a1 >> 4;
        a1 = a1 << 4;

        // Get second number
        c2 = c2 << 4; // 0xab -> 0xb0
        c2 = c2 >> 4; // 0xb0 -> 0x0b

        a2 = a2 << 4;
        a2 = a2 >> 4;

        if (a1 == c1 && a2 == c2) {
            return BettingResult.Win;
        }
        if (a1 == c1 || a1 == c2) {
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
        if (block.number >= BLOCK_LIMIT + answerBlockNumber) {
            return BlockStatus.BlockLimitPassed;
        }
        return BlockStatus.BlockLimitPassed;
    }

    function getBetInfo(uint256 index) public view returns (uint256 answerBlockNumber, address bettor, bytes memory challenges) {
        BetInfo memory b = _bets[index];
        answerBlockNumber = b.answerBlockNumber;
        bettor = b.bettor;
        challenges = b.challenges;
    }

    //betting 정보를 _bets queue에 저장한다.
    function pushBet(bytes memory challenges) internal returns (bool) {
        BetInfo memory b;
        b.bettor = payable(msg.sender); //20bytes
        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL; //32bytes
        b.challenges = challenges; // byte

        _bets[_tail] = b;
        _tail++; // 32byte 값 변화
        return true;
    }

    function popBet(uint256 index) internal returns (bool) {
        // map의 값을 delete 하게 되면 gas를 돌려받게 된다.
        delete _bets[index];
        return true;
    }
}