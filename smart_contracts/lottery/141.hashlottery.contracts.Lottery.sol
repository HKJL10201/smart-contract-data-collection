// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Lottery{

    // answer Block
    
    struct BetInfo {
        uint256 answerBlockNumber;
        // payable 적어줘야 transfer 가능
        address payable bettor;
        bytes1 challenges; //0xab
    }

    // QUEUE
    uint256 private _tail;
    uint256 private _head;
    mapping (uint256 => BetInfo) private _bets;

    // ??
    address payable public owner;
    
    // BLOCK HASH로 확인할 수 있는 제한 256
    uint256 constant internal BLOCK_LIMIT = 256;

    // 3번 블락에 배팅을 하게 되면 6번 블럭에 배팅을 하게 된다
    uint256 constant internal BET_BLOCK_INTERVAL = 3;

    // 베팅하는 금액 0.005ETH // 1ETH = 10 ** 18
    uint256 constant internal BET_AMOUNT = 5 * 10 ** 15;

    // pot money ??
    uint256 private _pot;

    bool private mode = false; // false : test mode(use answer for test), true : real mode(use real block hash)
    bytes32 public answerForTest;


    // BlockStatus Enum
    enum BlockStatus { Checkable, NotRevealed, BlockLimitPassed}

    // 매칭 결과 Enum
    enum BettingResult { Win, Fail, Draw}

    // EVENT
    event BET(uint256 index, address bettor, uint256 amount, bytes1 challenges, uint256 answerBlockNumber); // emit 자체 375gas + 파라미터 하나 당 375 gas + 파라미터 저장 될때 byte당 8gas => 4~5000 gas 
    event WIN(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event FAIL(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event DRAW(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event REFUND(uint256 index, address bettor, uint256 amount, bytes1 challenges, uint256 answerBlockNumber);

    
    // Constructor
    constructor() public {
        owner = msg.sender;
    }



    /* 
    view?: function 밖의 변수들을 읽을수 있으나 변경 불가능
    pure :?function 밖의 변수들을 읽지 못하고, 변경도 불가능
    view 와 pure 둘다 명시 안할때:?function 밖의 변수들을 읽어서, 변경을 해야함.
    */

    function getPot() public view returns (uint256 pot){
        return _pot;
    }


    /*
    * @dev 베팅과 정답체크를 한다. 유저는 0.005ETH를 보내야하고, 베팅용 1 byte 글자를 보낸다.
    * 큐에 저장된 베팅 정보는 이후 distribute 함수에서 해결된다.
    * @param challenges 유저가 베팅하는 글자
    * @return 함수가 잘 수행되었는지 확인하는 bool 값
    */

    function betAndDistribute(bytes1 challenges) public payable returns (bool result) {
        bet(challenges);
        distribute();
        return true;
    }

    //Bet

    /*
    * @dev 베팅을 한다. 유저는 0.005ETH를 보내야하고, 베팅용 1 byte 글자를 보낸다.
    * 큐에 저장된 베팅 정보는 이후 distribute 함수에서 해결된다.
    * @param challenges 유저가 베팅하는 글자
    * @return 함수가 잘 수행되었는지 확인하는 bool 값
    */
    
    function bet(bytes1 challenges) public payable returns (bool result) {

        // Check the proper ether is sent 
        // Not enough ETH
        require(msg.value == BET_AMOUNT, "Not enough ETH");

        // Push bet to the queue
        require(pushBet(challenges), "Fail to add a new Bet Info");

        // Emit event
        emit BET(_tail -1, msg.sender, msg.value, challenges, block.number + BET_BLOCK_INTERVAL);
        return true;

    }
    

    //Distribute 검증

    /*
    * @dev 베팅 결과값을 확인하고 팟머니를 분배한다.
    * 정답 실패 : 팟머니 축적
    * 정답 성공 : 팟머니 획득
    * 한글자맞춤 or 정답 확인 불가 : 배팅 금액만 획득
    */

    function distribute() public {
        // head 3 4 5 ... 11 12 tail
        uint256 cur;
        uint256 transferAmount;

        BetInfo memory b;
        BlockStatus currentBlockStatus;
        BettingResult currentBettingResult;

        for (cur = _head; cur < _tail; cur++) {

            // BetInfo 불러오기
            b = _bets[cur];
            currentBlockStatus = getBlockStatus(b.answerBlockNumber);

            // 먼저 BlockStatus 확인 3가지
            // Checkable : (block.number > answerBlockNumber) && (block.number < BLOCK_LIMIT + answerBlockNumber) (현재 블록보다 256 전까지만 확인할 수 있다 이게무슨말이지?)
            if (currentBlockStatus == BlockStatus.Checkable) {

                bytes32 answerBlockHash = getAnswerBlockHash(b.answerBlockNumber);

                currentBettingResult = isMatch(b.challenges,answerBlockHash);

                // Betting 결과에 따른 3가지 
                // if win , bettor가 pot money 가져감
                if (currentBettingResult == BettingResult.Win) {
                    // transfer pot
                    transferAmount = transferAfterPayingFee(b.bettor, _pot + BET_AMOUNT);
                    // pot = 0
                    _pot = 0;
                    // 여기서 transfer하고 _pot=0을 했는데, call이나 send일 경우엔 먼저 _pot을 임시변수에 저장해놓고 임시변수를 통해 전송을 한다음 진행하는게 안전

                    // emit Win event
                    emit WIN(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);

                }

                // if fail, bettor의 돈이 pot으로 감
                if (currentBettingResult == BettingResult.Fail) {
                    // pot = pot + BET_AMOUNT
                    _pot += BET_AMOUNT;
                    // emit Fail event
                    emit FAIL(cur, b.bettor, 0, b.challenges, answerBlockHash[0], b.answerBlockNumber);

                }

                // if draw (한글자만 맞춘 경우), refund bettor's money
                if (currentBettingResult == BettingResult.Draw) {
                    // transfer only BET_AMOUNT
                    transferAmount = transferAfterPayingFee(b.bettor,BET_AMOUNT);
                    // emit Draw event
                    emit DRAW(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);


                }
            }
            
            // block이 mining 되지 않은 상태(not revealed) : block.number <= answerBlockNumber // 등호가 붙은 이유 : 만들어지는 상태이므로 block.number 확인 불가
            if (currentBlockStatus == BlockStatus.NotRevealed) {
                break;
            }

            // block limit passed (지났을떄) : block.number >= BLOCK_LIMIT + answerBlockNumber
            if (currentBlockStatus == BlockStatus.BlockLimitPassed) {
                // refund
                transferAmount = transferAfterPayingFee(b.bettor,BET_AMOUNT);
                // emit refund
                emit REFUND(cur, b.bettor, transferAmount, b.challenges, b.answerBlockNumber);
            }

            popBet(cur);
        }
        _head = cur;
    }

    function transferAfterPayingFee(address payable addr, uint256 amount) internal returns (uint256) {
        // uint256 fee = amount / 100;
        uint256 fee = 0; // simple하게 하기 위해 0
        uint256 amountWithoutFee = amount - fee;

        // transfer to addr
        addr.transfer(amountWithoutFee);

        // transfer to owner
        owner.transfer(fee);

        return amountWithoutFee;
    }

    function setAnswerforTest(bytes32 answer) public returns (bool result) {
        require(msg.sender == owner, "Only owner can set the answer for test mode");
        answerForTest = answer;
        return true;
    }

    function getAnswerBlockHash(uint256 answerBlockNumber) internal view returns (bytes32 answer) {
        return mode ? blockhash(answerBlockNumber) : answerForTest;
    }

    /*
    * @dev 베팅글자와 정답을 확인한다.
    * @param challenges 베팅 글자
    * @param answer 블록 해쉬
    * @return 정답결과
    */
    function isMatch(bytes1 challenges, bytes32 answer) public pure returns (BettingResult) {

        // challenges 0xab = 1010 1011
        // answer 0xab......ff 32bytes

        bytes1 c1 = challenges;
        bytes1 c2 = challenges;

        bytes1 a1 = answer[0];
        bytes1 a2 = answer[0];

        // Get first number // challenges
        c1 = c1 >> 4; // 1010 1011 -> 0000 1010 // c1 = 0x0a
        c1 = c1 << 4; // 0000 1010 -> 1010 0000 // c1 = 0xa0

        // Get first number // answer[0]
        a1 = a1 >> 4;
        a1 = a1 << 4;

        // Get second number // challenges
        c2 = c2 << 4; // 1010 1011 -> 1011 0000 // c2 = 0xb0
        c2 = c2 >> 4; // 1011 0000 -> 0000 1011 // c2 = 0x0b

        // Get second number // answer[0]
        a2 = a2 << 4;
        a2 = a2 >> 4;

        if (a1 == c1 && a2 == c2) {
            return BettingResult.Win;
        }

        else if (a1 == c1 || a2 == c2) {
            return BettingResult.Draw;
        }

        else return BettingResult.Fail;
    }
        // Block 상태
        function getBlockStatus(uint256 answerBlockNumber) internal view returns (BlockStatus) {
            if (block.number > answerBlockNumber && block.number < BLOCK_LIMIT + answerBlockNumber) {
                return BlockStatus.Checkable;
            }
            else if (block.number <= answerBlockNumber) {
                return BlockStatus.NotRevealed;
            }
            else if (block.number >= BLOCK_LIMIT + answerBlockNumber) {
                return BlockStatus.BlockLimitPassed;
            }
            else return BlockStatus.BlockLimitPassed;
        }



    // _bets ? ?? ?? ???? getter
    function getBetInfo(uint256 index) public view returns(uint256 answerBlockNumber, address bettor, bytes1 challenges) {
        BetInfo memory b = _bets[index];
        answerBlockNumber = b.answerBlockNumber;
        bettor = b.bettor;
        challenges = b.challenges;
    }

    // QUEUE push
    function pushBet(bytes1 challenges) internal returns (bool) {
        BetInfo memory b;

        b.bettor = msg.sender; // 20 byte

        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL; // 32byte -> 20000 gas
        b.challenges = challenges; // byte -> 위에 msg.sender의 20byte + 하면 20000gas

        _bets[_tail] = b;
        _tail++; // 32byte // 20000 gas

        return true;
    }


    // QUEUE pop
    function popBet(uint256 index) internal returns (bool) {
        delete _bets[index];
        return true;
    }

}