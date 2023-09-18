// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Lottery{ 
    struct BetInfo {
        uint256 answerBlockNumber; // 맞추려고 하는 정답 block
        address payable bettor;  // 정답을 맞췄을 때 돈을 보내야 하는 주소 0.4.22버전 이상부터는 'payable' 붙여줘야함 아니면 transfer을 못함
        bytes1 challenges; // 0xab
    }

    uint256 private _tail;
    uint256 private _head;    
    mapping (uint256 => BetInfo) private _bets;
    
    address  payable public owner; // 주소를 owner로 설정

    uint256 constant internal BLOCK_LIMIT =256;
    uint256 constant internal BET_BLOCK_INTERVAL = 3; //3번 block에 betting을 하게되면 6번 block에 betting을 하게 됨
    uint256 constant internal BET_AMOUNT = 5 * 10 ** 15;
    uint256 private _pot;
    bool private mode = false; // false : use answer for test, true : real block hash
    bytes32 public answerForTest;

    enum BlockStatus {Checkable, NotRevealed, BlockLimitPassed}
    enum BettingResult {Fail, Win, Draw}

    event BET(uint256 index, address bettor, uint amount, bytes1 challenges, uint256 answerBlockNumber);
    event WIN(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event FAIL(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event DRAW(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event REFUND(uint256 index, address bettor, uint256 amount, bytes1 challenges, uint256 answerBlockNumber);

    constructor() public {
        owner = msg.sender; // 배포를 할 때 보낸 사람으로 owner를 저장
    }


    function getPot() public view returns (uint256 pot){
        return _pot;
    }

     /**
     * @dev 배팅과 정답 체크를 한다. 유저는 0.005 ETH를 보내야 하고, 베팅용 1 byte 글자를 보낸다.
     * 큐에 저장된 베팅 정보는 이후 distribute 함수에서 해결된다.
     * @param challenges 유저가 베팅하는 글자
     * @return result 함수가 수행되었는지 확인하는 bool 값
     */
    function betAndDistribute(bytes1 challenges) public payable returns (bool result) {
            bet(challenges);

            distribute();
            
            return true;        
    }
    /**
     * @dev 배팅을 한다. 유저는 0.005 ETH를 보내야 하고, 베팅용 1 byte 글자를 보낸다.
     * 큐에 저장된 베팅 정보는 이후 distribute 함수에서 해결된다.
     * @param challenges 유저가 베팅하는 글자
     * @return result 함수가 수행되었는지 확인하는 bool 값
     */
    function bet(bytes1 challenges) public  payable returns (bool result) {
        // 돈이 들어왔는지 확인
        require(msg.value == BET_AMOUNT, "Not enough ETH");

        // queue에 bet정보를 넣음
        require(pushBet(challenges), "Fail to add a new Bet Info");

        // event log를 출력
        emit BET(_tail -1, msg.sender, msg.value, challenges, block.number + BET_BLOCK_INTERVAL);

        return true;
    }
    

    
     /**
     * @dev 배팅 결과값을 확인하고 팟머니를 분배한다.
     * 정답 실패 : 팟 머니 축적, 정답 맞춤: 팟머니 획득, 한 글자 맞춤 or 정답 확인 불가 : 베팅 금액만 획득
     */
    function distribute() public {
         // head 3 4 5 6 7 8 10 tail
         uint256 cur;
         uint256 transferAmount; // <- 이벤트를 찍기위해 (실제 얼마가 전송이 되었는지 찍기위해)

         BetInfo memory b;
         BlockStatus currentBlockStatus;
         BettingResult currentBettingResult;

         for(cur=_head; cur <_tail; cur++) {
            b = _bets[cur];
            currentBlockStatus = getBlockStatus(b.answerBlockNumber);
            // checkable : block.number > answerblocknumber && block.number < BLOCK_LIMIT + answerBlocknumber 1
            if(currentBlockStatus == BlockStatus.Checkable){
                bytes32 answerBlockHash = getAnswerBlockHash(b.answerBlockNumber);
                currentBettingResult = isMatch(b.challenges, answerBlockHash);
                //if win, bettor gest pot
                if(currentBettingResult == BettingResult.Win){
                    // transfer pot
                    transferAfterPayingFee(b.bettor, _pot + BET_AMOUNT);
                    // pot == 0
                    _pot = 0;

                    // emit event Win
                    emit WIN(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }

                //if fail, bettor's money goes pot
                if(currentBettingResult == BettingResult.Fail){
                    // pot == pot + BET_AMOUNT
                    _pot +=  BET_AMOUNT;
                    // emit event Fail
                    emit FAIL(cur, b.bettor, 0, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }

                // if draw, refund bettor's money
                if(currentBettingResult == BettingResult.Draw){
                    // transfer only BET_AMOUNT
                     transferAfterPayingFee(b.bettor, BET_AMOUNT);

                    // emit event DRAW
                    emit DRAW(cur, b.bettor, BET_AMOUNT, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
            }
            // not Revealed: block.number <= answerblocknumber 2
            if(currentBlockStatus == BlockStatus.NotRevealed){
                break;
            }

            // block limit passed : block.number >= answerblocknumber + BLOCK_LIMIT 3
            if(currentBlockStatus == BlockStatus.BlockLimitPassed){
                // refund
                transferAfterPayingFee(b.bettor, BET_AMOUNT);

                // emit refund
                emit REFUND(cur, b.bettor, BET_AMOUNT, b.challenges, b.answerBlockNumber);

            }
            // check the answer
            popBet(cur);
            
         }
        _head = cur;
    }


    function transferAfterPayingFee(address payable addr, uint256 amount) internal returns(uint256) {
        
        // uint256 fee = amount / 100;
        uint256 fee = 0;
        uint256 amountWithoutFee = amount - fee;  // 전송한 금액에서 fee를 뺌

        //transfer to addr
        addr.transfer(amountWithoutFee);

        //transfer to owner
        owner.transfer(fee); // owner한테도 전송이 가능

        // 이더를 전송하는 3가지 방법 (이더 전송 -> 돈을 전송하는 방식이기 때문에 조심해서 관리해야 함)
        // call, send, transfer
        //그 중 transfer를 제일 많이 사용 (이더만 던져주고 이더를 던져주는게 실패하면 스마트 컨트랙트 안에서 fail시켜버림(가장 안전한 방법))
        // send도 전송하긴 하지만 false만 return함(트랜잭션이 fail나는 상황이 아님) -> try&catch로 해결
        // call -> 이더만 전송하는게 아니라 다른 스마트 컨트랙트의  특정 함수를 호출 할 때 사용

        return amountWithoutFee;
    }

    function setAnswerForTest(bytes32 answer) public  returns (bool result) {
        require(msg.sender == owner, "Only owner can set the answer for test mode");
        answerForTest = answer;
        return true;
    }

    function getAnswerBlockHash(uint256 answerBlockNumber) internal view returns (bytes32 answer) {
        return mode ? blockhash(answerBlockNumber) : answerForTest;
    }
    
    /**
    * @dev 베팅글자와 정답을 확인한다.
    * @param challenges 베팅 글자
    * @param answer 블락해쉬
    * @return 정답결과 
     */
    function isMatch (bytes1 challenges, bytes32 answer ) public pure returns (BettingResult) {
        //challenges 0xab
        // answer 0xab......ff 32 bytes

        bytes1 c1 = challenges;
        bytes1 c2 = challenges;

        bytes1 a1 = answer[0];
        bytes1 a2 = answer[0];

        //Get first number
        c1 = c1 >> 4;  // 0xab -> 0x0a
        c1 = c1 << 4;  // 0x0a -> 0xa0

        a1 = a1 >> 4;
        a1 = a1 << 4;

        //Get second number
        c2 = c2 << 4; // 0xab -> 0xb0
        c2 = c2 >> 4; // 0xb0 -> 0x0b

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
        if(block.number > answerBlockNumber && block.number < BLOCK_LIMIT + answerBlockNumber){
            return BlockStatus.Checkable;
        }

        if(block.number <= answerBlockNumber){
            return BlockStatus.NotRevealed;
        }

        if(block.number >= answerBlockNumber + BLOCK_LIMIT) {
            return BlockStatus.BlockLimitPassed;
        }
        return BlockStatus.BlockLimitPassed;
    }
    

    function getBetInfo(uint256 index) public view returns (uint256 answerBlockNumber, address bettor, bytes1 challenges){
        BetInfo memory b = _bets[index];
        answerBlockNumber = b.answerBlockNumber;
        bettor =b.bettor;
        challenges = b.challenges;
    }

    function pushBet(bytes1 challenges) internal returns (bool) {
        BetInfo memory b;
        b.bettor = msg.sender; // 20 bytes
        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL;   // 현재 이 트랜잭션 block의 들어있는 값을 불러올 수 있게 된다. // 32 bytes -> 20000 gas 
        b.challenges = challenges; //bytes  // 20000 gas

        _bets[_tail] =b;
        _tail++;  // 32 bytes 값 변화 // 20000 gas

        return true;
    }

    //delete를 쓰게 되면 gas를 돌려받게 됨
    // 스마트 컨트랙트 또는 이더리움 블록체인에 저장되어 있는 데이터를 더이상 저장하지 않겠다라는 의미
    function popBet(uint256 index) internal returns (bool) {
        delete _bets[index];
        return true;
    }
}