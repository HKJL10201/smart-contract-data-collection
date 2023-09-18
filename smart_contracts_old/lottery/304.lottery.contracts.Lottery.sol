pragma solidity >=0.4.21 <0.7.0;

contract Lottery {
    struct BetInfo {
        uint256 answerBlockNumber;
        address payable bettor; // payble 을 넣어야지 여기로 돈을 보낼 수 있음
        byte challenges;
    }

    // public 으로 만들면 자동으로 getter 를 만들어줌
    address payable public owner;
    
    uint256 private _pot;
    bool private mode = false; //false : test mode, true : use real black hash
    bytes32 public answerForTest;

    // smart contract 안에서만 사용하니까 internal
    uint256 constant internal BET_AMOUNT = 5 * 10 ** 15; // 0.005 ETH
    uint256 constant internal BET_BLOCK_INTERVAL = 3;
    uint256 constant internal BLOCK_LIMIT = 256;

    // queue 로 block 담기
    mapping(uint256 => BetInfo) private _bets;
    uint256 private _tail;
    uint256 private _head;

    enum BlockStatus {Checkable, NotRevealed, BlockLimitPassed}
    enum BettingResult {fail, win, draw}

    event BET(uint256 index, address bettor, uint256 amount, byte challenges, uint256 answerBlockNumber);
    event WIN(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event FAIL(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event DRAW(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event REFUND(uint256 index, address bettor, uint256 amount, byte challenges, uint256 answerBlockNumber);

    constructor() public {
        owner = msg.sender;
    }

    // smart contract 내부 값을 볼 때는 view 를 이용
    function getPot() public view returns (uint256 pot) {
        return _pot;
    }

    /**
     * @dev 베팅과 분배를 한번에 한다
     * @param challenges 유저가 베팅하는 글자
     * @return 함수가 잘 수행되었는지 확인하는 bool 값
     */
    function betAndDistribute(byte challenges) public payable returns (bool result) {
        bet(challenges);
        distribute();
        return true;
    }

    /**
     * @dev 베팅을 한다. 유저는 0.005 ETH 와 함께 1 bytr 글자를 보낸다.
     * 큐에 저장된 베팅 정보는 이후 distribute 함수에서 해결
     * @param challenges 유저가 베팅하는 글자
     * @return 함수가 잘 수행되었는지 확인하는 bool 값
     */
    // 사람이 베팅할 때 돈을 보내니까 payable
    function bet(byte challenges) public payable returns (bool result){
        // Check the proper ether is sent
        require(msg.value == BET_AMOUNT, "Not enough ETH");
        
        // Push bet to the queue
        require(pushBet(challenges), "Fail to add a new Bet Info");
        
        // Emit event
        emit BET(_tail-1, msg.sender, msg.value, challenges, block.number + BET_BLOCK_INTERVAL);

        return true;
    }

    /**
     * @dev 베팅 결과를 확인하고, 팟머니를 배분한다.
     * 정답 실패 : 팟머니 축적, 정답 맞춤 : 팟머니 획득, 한글자 맞춤 or 정답 확인불가 : 배팅금액 환불
     */
    // Distribute (분배)
    function distribute() public {
        uint256 cur;
        uint256 transferAmount;
        BetInfo memory b;
        BlockStatus currentBlockStatus;
        BettingResult currentBettingResult;

        for(cur = _head; cur < _tail; cur++){
            b = _bets[cur];
            currentBlockStatus = getBlockStatus(b.answerBlockNumber);
            // 확인!
            if(currentBlockStatus == BlockStatus.Checkable){
                bytes32 answerBlockHash = getAnswerBlockHash(b.answerBlockNumber);
                currentBettingResult = isMatch(b.challenges, getAnswerBlockHash(b.answerBlockNumber));
                // if win, bettor gets pot
                if(currentBettingResult == BettingResult.win) {
                    // transfer pot
                    transferAmount = transferAterPayingFee(b.bettor, _pot + BET_AMOUNT);

                    // pot = 0
                    _pot = 0;

                    // emit Win
                    emit WIN(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
                // if fail, bettor's money goes pot
                if(currentBettingResult == BettingResult.fail) {
                    // pot = pot + BET_AMOUNT
                    _pot += BET_AMOUNT;

                    // emit Fail
                    emit FAIL(cur, b.bettor, 0, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
                // if draw, refund bettor's money
                if(currentBettingResult == BettingResult.draw) {
                    // transfer only BET_AMOUNT
                    transferAmount = transferAterPayingFee(b.bettor, BET_AMOUNT);

                    // emit Draw
                    emit DRAW(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
            }

            // block hash를 확인할 수 없을 때
            // 1.아직 마이닝 안됐을 떄
            if(currentBlockStatus == BlockStatus.NotRevealed){
                break; // 뒤에도 어차피 없으니까
            }
            // 2.너무 예전 블록일 때
            if(currentBlockStatus == BlockStatus.BlockLimitPassed){
                // refund
                transferAmount = transferAterPayingFee(b.bettor, BET_AMOUNT);

                // emit refund
                emit REFUND(cur, b.bettor, transferAmount, b.challenges, b.answerBlockNumber);
            }
            popBet(cur);

        }
        _head = cur;
    }

    function transferAterPayingFee(address payable addr, uint256 amount) internal returns (uint256) {
        uint256 fee = 0;
        uint256 amountWithoutFee = amount - fee;

        // transfer to addr
        addr.transfer(amountWithoutFee);

        // transfer to owner
        owner.transfer(fee);

        return amountWithoutFee;
    }

    function setAnswerForTest(bytes32 answer) public returns (bool result) {
        require(msg.sender == owner, "Only onwer can set the answer for test mode");
        answerForTest = answer;
        return true;
    }

    function getAnswerBlockHash(uint256 answerBlockNumber) internal view returns (bytes32 answer) {
        return mode ? blockhash(answerBlockNumber) : answerForTest ;
    }

    /**
     * @dev 베팅 글자와 정답을 확인
     * @param challenges 베팅 글자
     * @param answer block hash
     * @param 베팅 결과
     */
    function isMatch(byte challenges, bytes32 answer) public pure returns(BettingResult) {
        byte c1 = challenges;
        byte c2 = challenges;
        byte a1 = answer[0];
        byte a2 = answer[0];

        c1 = c1 >> 4; // 0xab -> 0x0a
        c1 = c1 << 4; // 0x0a -> 0xa0

        a1 = a1 >> 4;
        a1 = a1 << 4;

        c2 = c2 << 4;
        c2 = c2 >> 4;

        a2 = a2 << 4;
        a2 = a2 >> 4;

        if(a1 == c1 && a2 == c2) {
            return BettingResult.win;
        }

        if(a1 == c1 || a2 == c2) {
            return BettingResult.draw;
        }

        return BettingResult.fail;
    }

    function getBlockStatus(uint256 answerBlockNumber) internal view returns(BlockStatus) {
        if(answerBlockNumber < block.number && block.number < BLOCK_LIMIT + answerBlockNumber) {
            return BlockStatus.Checkable;
        }
        if(answerBlockNumber >= block.number) {
            return BlockStatus.NotRevealed;
        }
        if(block.number >= BLOCK_LIMIT + answerBlockNumber) {
            return BlockStatus.BlockLimitPassed;
        }

        // 에러나면 그냥 환불해주는거지..
        return BlockStatus.BlockLimitPassed;
    }

    function getBetInfo(uint256 index) public view returns (uint256 answerBlockNumber, address bettor, byte challenges) {
        BetInfo memory b = _bets[index];
        answerBlockNumber = b.answerBlockNumber;
        bettor = b.bettor;
        challenges = b.challenges;
    }

    function pushBet(byte challenges) internal returns (bool) {
        BetInfo memory b;
        b.bettor = msg.sender;
        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL;
        b.challenges = challenges;

        _bets[_tail] = b;
        _tail++;

        return true;
    }

    function popBet(uint256 index) internal returns (bool) {
        // delete 를 하면 gas를 돌려받게 된다.
        delete _bets[index];
        return true;
    }
}