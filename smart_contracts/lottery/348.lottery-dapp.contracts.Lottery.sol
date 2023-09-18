// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

contract Lottery {
    struct BetInfo {
        uint answerBlockNumber;
        address payable gambler;
        bytes1 challenges;
    }

    address payable public owner;
    bytes32 public answerForTest;

    uint constant internal BLOCK_LIMIT = 256;
    uint constant internal BET_BLOCK_INTERVAL = 3;
    uint constant internal BET_AMOUNT = 0.005 ether;

    mapping(uint => BetInfo) private _bets;
    uint private _tail;
    uint private _head;
    uint private _pot;
    bool private mode = false; // false: test mode, true: real mode

    enum BlockStatus {
        Checkable, NotRevealed, BlockLimitPassed
    }

    enum BettingResult {
        Win, Fail, Draw
    }

    event BET(uint index, address gambler, uint amount, bytes1 challenges, uint answerBlockNumber);
    event WIN(uint index, address gambler, uint amount, bytes1 challenges, bytes1 answer, uint answerBlockNumber);
    event FAIL(uint index, address gambler, uint amount, bytes1 challenges, bytes1 answer, uint answerBlockNumber);
    event DRAW(uint index, address gambler, uint amount, bytes1 challenges, bytes1 answer, uint answerBlockNumber);
    event REFUND(uint index, address gambler, uint amount, bytes1 challenges, uint answerBlockNumber);

    constructor() {
        owner = payable(msg.sender);
    }


    /**
     * @dev 베팅과 정답 체크를 한다.
     * @param challenges 예측값
     * @return 함수가 잘 수행되었는지 확인 
     */
    function betAndDistribute(bytes1 challenges) public payable returns (bool) {
        bet(challenges);

        distribute();

        return true;
    }

    /**
     * @dev 베팅을 한다. 유저는 0.005 ETH를 보내야하고, 다음 세번째 블록의 해시값의 앞 네 자리 예측 글자를 보낸다.(앞 0x는 고정)
     * @param challenges 예측값
     * @return 함수가 잘 수행되었는지 확인 
     */
    function bet(bytes1 challenges) public payable returns (bool) {
        require(msg.value == BET_AMOUNT, "Not enough ETH");

        require(pushBet(challenges), "Fail to ad new Bet Info");

        emit BET(_tail - 1, msg.sender, msg.value, challenges, block.number + BET_BLOCK_INTERVAL);

        return true;
    }

    /**
     * @dev 베팅결과를 확인하고 팟머니를 분배한다.
     * 한 글자도 못 맞추면 실패: 팟머니에 베팅액 축적.
     * 두 글자 모두 맞추면 성공: 팟머니 획득.
     * 한 글자만 맞추었거나 정답을 확인할 수 없는 경우 : 베팅액 돌려줌.
     */
    function distribute() public {
        uint cur;
        uint transferAmount;
        BetInfo memory b;
        BlockStatus status;
        BettingResult result;

        for(cur=_head; cur <= _tail; cur++) {
            b = _bets[cur];
            status = getBlockStatus(b.answerBlockNumber);

            if(status == BlockStatus.Checkable) {
                bytes32 answer = getAnswerBlock(b.answerBlockNumber);
                result = isMatch(b.challenges, answer);
                
                if(result == BettingResult.Win) {
                    transferAmount = transferAfterPayingFee(b.gambler, _pot + BET_AMOUNT);
                    _pot = 0;

                    emit WIN(cur, b.gambler, transferAmount, b.challenges, answer[0], b.answerBlockNumber);
                }

                if(result == BettingResult.Fail) {
                    _pot += BET_AMOUNT;

                    emit FAIL(cur, b.gambler, 0, b.challenges, answer[0], b.answerBlockNumber);
                }

                if(result == BettingResult.Draw) {
                    transferAmount = transferAfterPayingFee(b.gambler, BET_AMOUNT);

                    emit DRAW(cur, b.gambler, transferAmount, b.challenges, answer[0], b.answerBlockNumber);
                }
            }

            if(status == BlockStatus.NotRevealed) {
                break;
            }

            if(status == BlockStatus.BlockLimitPassed) {
                transferAmount = transferAfterPayingFee(b.gambler, BET_AMOUNT);

                emit REFUND(cur, b.gambler, transferAmount, b.challenges, b.answerBlockNumber);
            }
 
            
            popBet(cur);
        }

        _head = cur;
    }

    function getPot() public view returns(uint pot) {
        return _pot;
    }

    function getBetInfo(uint index) public view returns (uint answerBlockNumber, address gambler, bytes1 challenges) {
        BetInfo memory b = _bets[index];
        answerBlockNumber = b.answerBlockNumber;
        gambler = b.gambler;
        challenges = b.challenges;
    }

    /**
     * @dev 배팅 글자와 정답을 확인한다.
     * @param challenges 배팅 글자
     * @param answer 블럭 해시
     * @return 정답결과
     */
    function isMatch(bytes1 challenges, bytes32 answer) public pure returns(BettingResult) {
        bytes1 c1 = getFirstWord(challenges);
        bytes1 c2 = getSecondWord(challenges);

        bytes1 a1 = getFirstWord(answer[0]);
        bytes1 a2 = getSecondWord(answer[0]);

        if (c1 == a1 && c2 == a2) {
            return BettingResult.Win;
        }

        if (c1 == a1 || c2 == a2) {
            return BettingResult.Draw;
        }

        return BettingResult.Fail;
    }

    function setAnswerForTest(bytes32 answer) public returns(bool) {
        require(msg.sender == owner, "only owner can set answer for test");
        answerForTest = answer;
        return true;
    }

    function getFirstWord(bytes1 word) internal pure returns(bytes1) {
        bytes1 w = word;
        w = w >> 4;
        w = w << 4;
        return w;
    }

    function getSecondWord(bytes1 word) internal pure returns(bytes1) {
        bytes1 w = word;
        w = w << 4;
        w = w >> 4;
        return w;
    }

    function pushBet(bytes1 challenges) internal returns (bool) {
        BetInfo memory b;
        b.gambler = payable(msg.sender);
        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL;
        b.challenges = challenges;

        _bets[_tail] = b;
        _tail++;

        return true;
    }

    function popBet(uint index) internal returns (bool) {
        delete _bets[index];
        return true;
    }

    function getBlockStatus(uint answerBlockNumber) internal view returns(BlockStatus) {
        if(block.number > answerBlockNumber && block.number < answerBlockNumber + BLOCK_LIMIT) {
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

    function getAnswerBlock(uint answerBlockNumber) internal view returns(bytes32 answer) {
        return mode ? blockhash(answerBlockNumber) : answerForTest;
    }

    function transferAfterPayingFee(address payable gambler, uint amount) internal returns (uint) {
        uint fee = mode ? amount / 100 : 0;
        uint amountWithoutFee = amount - fee;

        gambler.transfer(amountWithoutFee);

        owner.transfer(fee);

        return amountWithoutFee;
    }

}
