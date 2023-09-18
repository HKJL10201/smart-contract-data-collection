pragma solidity >=0.4.22 <0.9.0;

contract Lottery {
    struct BetInfo {
        uint256 answerBlockNumber; // 맞추려고 하는 정답블럭(+3)의 주소
        address payable bettor; // 정답을 맞췄으면 이 주소에 돈을 보낸다. = 돈을 보내려면 payable을 써줘야 돈이 감 = 근데 payable쓰니까 오류나서 지움(찾아보니 디폴트란다)
        bytes1 challenges; // 정답이 들어옴
    }

    uint256 private _tail;
    uint256 private _head;
    mapping(uint256 => BetInfo) private _bets;

    address payable public owner;

    uint256 internal constant BLOCK_LIMIT = 256;
    uint256 internal constant BET_BLOCK_INTERVAL = 3;
    uint256 internal constant BET_AMOUNT = 5 * 10**15;

    uint256 private _pot;
    bool private _mode = false; // false =test mode , true = real block hash
    bytes32 public answerForTest;
    
    enum BlockStatus { Checkable, NotRevealed, BlockLimitPassed }
    enum BettingResult { Fail, Win, Draw }

    event BET( uint256 index, address bettor, uint256 amount, bytes1 challenges, uint256 answerBlockNumber );
    event WIN( uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumver);
    event FAIL( uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumver);
    event DRAW( uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumver);
    event REFUND( uint256 index, address bettor, uint256 amount, bytes1 challenges, uint256 answerBlockNumver);
    
    constructor() public {
        owner = payable(msg.sender);
    }

    function getPot() public view returns (uint256 pot) {
        return _pot;
    }
    
    function betAndDistribute(bytes1 challenges) public payable returns(bool result){
        bet(challenges);
        Distribute();
        return true;
    }

    /**
     * @dev 배팅을 한다. 유저는 0.005이더를 보내고 배팅용 1byte 글자를 보낸다.
     * 큐에 저장된 배팅정보는 이후 distribute 함수에서 해결한다.
     * @param challenges 유저가 배팅하는 글자
     */
    function bet(bytes1 challenges) public payable returns (bool result) {
        // 이더가 보내졌는지 확인
        require(msg.value == BET_AMOUNT, "not enough ETH");

        // 큐에 베팅 정보를 넣음
        require(pushBet(challenges), "Fail to add New Bet Info");

        // 이벤트 로그를 찍고 true를 리턴
        emit BET( _tail - 1, msg.sender, msg.value, challenges, block.number + BET_BLOCK_INTERVAL );
        
        return true;
    }

    /**
     * @dev 배팅 결과값을 확인하고 팟머니를 분배한다.
     * 정답실패 : 팟머니 축척, 정답맞춤 : 팟머니 획득, 한글자 맞춤 or 정답 확인 불가 : 배팅금액
     */
    function Distribute() public {
        uint256 cur;
        uint256 transferAmount;

        BetInfo memory b;
        BlockStatus currentBlockStatus;
        for (cur = _head; cur < _tail; cur++) {
            b = _bets[cur];
            currentBlockStatus = getBlockStatus(b.answerBlockNumber);
            BettingResult currentBettingResult;

            // checkable : block.number > answerBlockNumber && block.number < BLOCK_LIMIT + answerBlockNumber
            if (currentBlockStatus == BlockStatus.Checkable) {
                bytes32 answerBlockHash = getAnswerBlockHash(b.answerBlockNumber);
                currentBettingResult = isMatch(b.challenges, answerBlockHash);
                // if win, bettor get potmoney
                if(currentBettingResult == BettingResult.Win){
                    //transfer pot money
                    transferAmount = transferAfterPayingFee(b.bettor, _pot + BET_AMOUNT);
                    // 현재 pot = 0
                    _pot = 0;
                    emit WIN( cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                    //
                }
                // if fail, bettor go to potmone
                if(currentBettingResult == BettingResult.Fail){
                    // pot = pot + BET_AMOUNT
                    _pot += BET_AMOUNT;
                    emit FAIL( cur, b.bettor, 0, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
                
                // if draw, bettor refund
                if(currentBettingResult == BettingResult.Draw){
                    // transfer only bet amount
                    transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);
                    // emit DRAW
                    emit DRAW( cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
                
            }
            // block check가 불가능한 상태(not rebuilded) : block.number <= answerBlockNumber
            if (currentBlockStatus == BlockStatus.NotRevealed) {
                break;
            }
            // block limit passed : block.number >= answerBlockNumber + BLOCK_LIMIT
            if (currentBlockStatus == BlockStatus.BlockLimitPassed) {
                // 환불
                transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);
                // emit refund
                emit REFUND(cur, b.bettor, transferAmount, b.challenges, b.answerBlockNumber);
            }
            popBet(cur);
        }
        _head = cur;
    }

    // 수수료 함수
    function transferAfterPayingFee(address payable addr, uint256 amount) internal returns(uint256){
       
       // 수수료
        uint256 fee = 0;
        uint256 amountWithoutFee = amount - fee;

        // transfer to address
        addr.transfer(amountWithoutFee);

        // transfer to owner
        owner.transfer(fee);

        // 스마트에서 이더를 전송하는 방법 : call, send, transfer (가장 많이 사용함)
        // transfer : 이더를 전송하는데 실패하면 트랜잭션 자체를 fail시킨다.
        // call : 다른 스마트 컨트랙트의 특정 함수를 호출하고 그때 같이 이더를 보낼 수 있다. 외부에 있는 스마트컨트랙트를 사용하며 돈을 전송하면 굉장히 위험하다.
        // send : 트랜잭션이 실패했을때 처리하는 부분을 내가 생각해야 한다.

        return amountWithoutFee;
    }

    function setAnswerForTest (bytes32 answer) public returns(bool result){
        require(msg.sender == owner,"Only owner can set the answer of test mode");
        answerForTest = answer;
        return true;
    }
    function getAnswerBlockHash (uint256 answerBlockNumber) internal view returns (bytes32 answer){
        return _mode ? blockhash(answerBlockNumber) : answerForTest;
    }

    /**
     * @dev 매칭 글자와 정답을 확인한다.
     * @param challenges 배팅 글자
     * @param answer 블럭 해쉬
     * @return 정답 결과
     */
    function isMatch(bytes1 challenges, bytes32 answer) public pure returns (BettingResult) {
        bytes1 c1 = challenges;
        bytes1 c2 = challenges;

        bytes1 a1 = answer[0];
        bytes1 a2 = answer[0];

        // get first num
        c1 = c1 >> 4;
        c1 = c1 << 4;

        a1 = a1 >> 4;
        a1 = a1 << 4;

        // get second num
        c2 = c2 << 4;
        c2 = c2 >> 4;

        a2 = a2 << 4;
        a2 = a2 >> 4;

        if( a1 == c1 && a2 == c2 ){
            return BettingResult.Win;
        }
        if (a1 == c1 || a2 == c2 ){
            return BettingResult.Draw;
        }
        return BettingResult.Fail;
    }

    function getBlockStatus(uint256 answerBlockNumber) internal view returns (BlockStatus) {
        if (
            block.number > answerBlockNumber &&
            block.number < BLOCK_LIMIT + answerBlockNumber
        ) {
            return BlockStatus.Checkable;
        }

        if (block.number <= answerBlockNumber) {
            return BlockStatus.NotRevealed;
        }

        if (block.number >= answerBlockNumber + BLOCK_LIMIT) {
            return BlockStatus.BlockLimitPassed;
        }

        return BlockStatus.BlockLimitPassed;
    }

    function getBetInfo(uint256 index) public view returns ( uint256 answerBlockNumber, address bettor, bytes1 challenges ) {
        BetInfo memory b = _bets[index];
        answerBlockNumber = b.answerBlockNumber;
        bettor = b.bettor;
        challenges = b.challenges;
    }

    function pushBet(bytes1 challenges) internal returns (bool) {
        BetInfo memory b;
        b.bettor = payable(msg.sender); // 20btyes
        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL; // 32bytes = 20000가스
        b.challenges = challenges; //btyes1
        // bettor + challenges == 20000gas

        _bets[_tail] = b;
        _tail++;
        // 32bytes변화 : 20000gas = 첫번째 컨트렉트 제외하고는 5000gas가 소모됨.

        return true;
    }

    function popBet(uint256 index) internal returns (bool) {
        delete _bets[index]; // map의 값을 지우면 gas를 돌려받게 된다.
        return true;
    }
}
