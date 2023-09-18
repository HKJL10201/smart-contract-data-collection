// // SPDX-License-Identifier: MIT
// pragma solidity ^0.6.0;

// contract Lottery {

//   struct BetInfo{
//     uint256 answerBlockNumber;//우리가 맞추려는 정답의 블록 number
//     address payable bettor;//정답을 맞추면 better에게 보내줘야 함. 그래서 payable을 써주ㅕ야 함.
//     byte challenges;
//   }
//   uint256 constant internal BLOCK_LIMIT = 256;
//   uint256 constant internal BET_BLOCK_INTERVAL = 3;
//   uint256 constant internal BET_AMOUNT = 5 * 10 ** 15; 

//   enum BlockStatus {Checkable, NotRevealed, BlockLimitPassed}

//   uint256 private _tail;
//   uint256 private _head;
//   mapping (uint256 => BetInfo) private _bets;//queue
//   address payable public owner;

//   bool private mode = false;// false:devmod
//   bytes32 public answerForTest;

//   uint256 private _pot;//팟머니를 만들 곳

//   constructor() public {
//     owner = msg.sender;
//   }

//   // function getSomeValue() public pure returns (uint value){
//   //   return 5;
//   // }
//   event BET(uint256 index,address indexed bettor, uint256 amount, byte challenges, uint256 answerBlockNumber,uint256 pod);
//   event WIN(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
//   event FAIL(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber, uint256 pot);
//   event DRAW(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
//   event REFUND(uint256 index, address bettor, uint256 amount, byte challenges, uint256 answerBlockNumber); 
//   event LOUD(string str);
//   event NUMBER(string mem, uint256 number);
//   //정답을 알 수 없으니까
  

//   function getPot() public view returns (uint256 pot) {
//     return _pot;
//   }

//    /**
//   *@dev  배팅과 정답 체크를 한다.
//   *@param challenges 유저가 배팅하는 글자
//   */
//   function betAndDistribute(byte challenges) public payable returns (bool result) {
//     bet(challenges);
//     distribute();
//     return true;
//   }

//   function getBetInfo(uint256 index)public view returns (uint256 answerBlockNumber, address bettor, byte challenges) {
//     BetInfo memory b = _bets[index];
//     answerBlockNumber = b.answerBlockNumber;
//     bettor = b.bettor;
//     challenges = b.challenges;
//   } 
//   function pushBet(byte challenges) internal returns (bool) {
//     BetInfo memory b;
//     b.bettor = msg.sender;
//     b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL;
//     b.challenges = challenges;

//     _bets[_tail] = b;
//     _tail++;

//     return true;

//   }

//   function popBet(uint256 index) internal returns (bool){
//     delete _bets[index];
//     return true;
//     //딜리트를하면 가스가 환불이 된다. 상태 데이터베이스의 값을 없애겠다는 것임.
//     //필요하지 않는 값에 대해서는 delete를 해주는 것이 맞다. 
//   }
//   //bet

//   /**
//   * @dev 배팅을 한다. 유저는 0.005eth를 보내야 하고 배팅용 1byte 글자를 보낸다.
//   *큐에 저장된 배팅 정보는 이후 distribution 에 저장된다. 
//   *@param challenges 유저가 배팅하는 글자
//   *@return 함수가 잘 수행되었느지 확인하는 bool값
//    */
//   function bet(byte challenges) public payable returns (bool result) {
//     //1. check the propter ether is sent
//     require(msg.value == BET_AMOUNT,"Not enough ETH" );

//     //2. push bet to the queue
//     require(pushBet(challenges),"Fail to add a new Bet Info");
//     //3. emit event log
//     emit BET(_tail - 1, msg.sender, msg.value , challenges, block.number + BET_BLOCK_INTERVAL,_pot);
//     return true;
//   }

//   //정답을 지정할 수 있게 setterFunction 도 만들어준다.ㅣ 
//   function setAnswerForTest(bytes32 answer) public returns (bool result){
//     require(msg.sender ==owner, "Only owner can set the answer ");
//     answerForTest = answer;
//     return true;
//   }

//   function getAnswerBlockHash(uint256 answerBlockNumber) internal view returns (bytes32 answer){
//     return mode ?  blockhash(answerBlockNumber): answerForTest;
//   } 



//   /**
//   *@dev 배팅 결과값을 확인하고 팟머니를 분배한다. 
//   *정답실패: 팟머니 축적, 정답 맞춤: 팟머니 획득, 한글자 맞춤 or 정답 확인 불가: 배팅 금액만 획득
//   */
//    function distribute() public {
//     uint256 cur;
//     uint256 transferAmount; // 이유: 얼마나 보냈는지 찍기 위해서

//     BetInfo memory b;
//     BlockStatus currentBlockStatus;
//     BettingResult currentBettingResult;
    
//     for(cur=_head; cur<_tail; cur++){
//         b = _bets[cur];
//         currentBlockStatus = getBlockStatus(b.answerBlockNumber);
//         // outStatus(currentBlockStatus);
//         emit NUMBER('currentBlock',block.number);
//         emit NUMBER('b.answerBlockNumber',b.answerBlockNumber);
//       //Checkable: block.number > AnswerBlockNumber && block.number < BLOCK_LIMIT + AnswerBlockNumber 1
//         if(currentBlockStatus == BlockStatus.Checkable){
//           // emit LOUD('체커블');
//           bytes32 answerBlockHash = getAnswerBlockHash(b.answerBlockNumber);
//           currentBettingResult = isMatch(b.challenges,answerBlockHash);//결과값을 가져옴
//           //if win, bettor gets pot
//           if(currentBettingResult == BettingResult.Win){
//               //transfet pot/수수료를 떼가는 함수 만들자 trnasferAfterPaingFee
//               transferAmount = transferAfterPayingFee(b.bettor, _pot + BET_AMOUNT);//아직 내가 배팅한 금액은 추가되지 않았기 때문에
//               // pot = 9
//               _pot = 0;
//               //transfer여서 이렇게 쓰는 것임

//               //emit Win
//               emit WIN(cur, b.bettor, transferAmount, b.challenges,answerBlockHash[0], b.answerBlockNumber);
//           }
//           //if fail, bettor's money goes pot
//           if(currentBettingResult == BettingResult.Fail){
//             emit LOUD('실패함');
//               //pot = pot + BET_AMOUNT
//               _pot += BET_AMOUNT;
//               //emit FAIL
//               emit FAIL(cur, b.bettor, 0, b.challenges,answerBlockHash[0], b.answerBlockNumber, _pot);
//           }
//         //if draw, refund bettor's money
//           if(currentBettingResult == BettingResult.Draw){
//               //transfer only BET_AMOUNT
//               transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);
              
//               //emit DRAW
//               emit DRAW(cur, b.bettor, transferAmount, b.challenges,answerBlockHash[0], b.answerBlockNumber);
//           }
//         //Not Revealed: block.number <= AnswerBlockNumber 2
//         if(currentBlockStatus == BlockStatus.NotRevealed) {
//           emit LOUD('마이닝 덜 됨');
//           break;//아직 마이닝이 되지 않았다.
//         }

//         //Block Limit Passed : block.number >= AnswerBlockNumber+ Block_LiMIT 3
//         if(currentBlockStatus == BlockStatus.BlockLimitPassed){
//           //refund
//            emit LOUD('더 지나가는거');
//           transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);

//           //emit refund
//           emit REFUND(cur, b.bettor, transferAmount, b.challenges, b.answerBlockNumber);
//         }
//          emit LOUD('아무것도 안됨');
//         popBet(cur);

//       }
//       _head = cur;

//       //Not Revealed

//       //Block Limit Passed
//     }
//   }
//   // function outStatus(BlockStatus blockstatus) public returns (string) {
//   //   if(BlockStatus.)
//   // }
//   function transferAfterPayingFee(address payable addr, uint256 amount) internal returns (uint256){
//     // uint256 fee = amount /100; 
//     uint256 fee = 0;
//     uint256 amountWithoutFee = amount - fee;
//     //transfer to addr
//     addr.transfer(amountWithoutFee);
//     //transfer to owner
//     owner.transfer(fee);
//     return amountWithoutFee;
  
//   }
//   function getBlockStatus(uint answerBlockNumber) internal  returns (BlockStatus){
//     if(block.number > answerBlockNumber && block.number < BLOCK_LIMIT +  answerBlockNumber) {
//       emit LOUD('체커블');
//       return BlockStatus.Checkable;
//     }
//     if(block.number<=answerBlockNumber){
//       emit LOUD('드러낼 수 없음');
//       return BlockStatus.NotRevealed;
//     }
//     if(block.number >= answerBlockNumber + BLOCK_LIMIT) {
//       emit LOUD('넘겨버려');
//       return BlockStatus.BlockLimitPassed;
//     }
//     return BlockStatus.BlockLimitPassed;
//   }
//   enum BettingResult { Fail, Win,Draw }

//   /**
//   *@dev 배팅 글자와 정답을 확인한다.
//   *@param challenges 배팅 글자
//   *@param answer 블록해시
//   *@return 정답 결과
//   */



//   function isMatch(byte challenges, bytes32 answer) public pure returns (BettingResult) {
//     //challenges  에는 0xab이렇게 들어올 것이다.ㅣ 
//     //answer 0xab...........ff 32byte로 들어올 것이다.ㅣ 
//     byte c1 = challenges;
//     byte c2 = challenges;

//     byte a1 = answer[0];
//     byte a2 = answer[0];

//     //Get first number
//     c1 = c1 >> 4; 
//     c1 = c1 << 4;

//     //0xab=>0x0a=>0xa0

//     a1 = a1 >> 4;
//     a1 = a1 << 4;
    
//     //Get Second Number
//     c2 = c2 << 4;
//     c2 = c2 >> 4;

//     a2 = a2 << 4;
//     a2 = a2 >> 4;
//     //0xab => 0xb0 =>0x0b;
  
//     if(a1 == c1 && a2 == c2) {
//       return BettingResult.Win;
//     }
//     if(a1 == c1 || a2 == c2) {
//       return BettingResult.Draw;
//     }
//     return BettingResult.Fail;

  
//   }

 
// }
// //결과값을 겁ㅁ증해야 하는데 Bet 과 Distribute로 하면 될 듯
// //save the bet to the queue
// //distribute
// //r값이 틀리면 넣고 



/*******************************붙여넣기함 */
pragma solidity ^0.6.0;


contract Lottery {
    struct BetInfo {
        uint256 answerBlockNumber;
        address payable bettor;
        byte challenges;
    }
    
    uint256 private _tail;
    uint256 private _head;
    mapping (uint256 => BetInfo) private _bets;

    address payable public owner;
    
    
    uint256 private _pot;
    bool private mode = false; // false : use answer for test , true : use real block hash
    bytes32 public answerForTest;

    uint256 constant internal BLOCK_LIMIT = 256;
    uint256 constant internal BET_BLOCK_INTERVAL = 3;
    uint256 constant internal BET_AMOUNT = 5 * 10 ** 15;

    enum BlockStatus {Checkable, NotRevealed, BlockLimitPassed}
    enum BettingResult {Fail, Win, Draw}

    event BET(uint256 index, address indexed bettor, uint256 amount, byte challenges, uint256 answerBlockNumber);
    event WIN(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event FAIL(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event DRAW(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event REFUND(uint256 index, address bettor, uint256 amount, byte challenges, uint256 answerBlockNumber);

    constructor() public {
        owner = msg.sender;
    }

    function getPot() public view returns (uint256 pot) {
        return _pot;
    }

    /**
     * @dev 베팅과 정답 체크를 한다. 유저는 0.005 ETH를 보내야 하고, 베팅용 1 byte 글자를 보낸다.
     * 큐에 저장된 베팅 정보는 이후 distribute 함수에서 해결된다.
     * @param challenges 유저가 베팅하는 글자

     */
    function betAndDistribute(byte challenges) public payable returns (bool result) {
        bet(challenges);

        distribute();

        return true;
    }

    // 90846 -> 75846
    /**
     * @dev 베팅을 한다. 유저는 0.005 ETH를 보내야 하고, 베팅용 1 byte 글자를 보낸다.
     * 큐에 저장된 베팅 정보는 이후 distribute 함수에서 해결된다.
     * @param challenges 유저가 베팅하는 글자
     */
    function bet(byte challenges) public payable returns (bool result) {
        // Check the proper ether is sent
        require(msg.value == BET_AMOUNT, "Not enough ETH");

        // Push bet to the queue
        require(pushBet(challenges), "Fail to add a new Bet Info");

        // Emit event
        emit BET(_tail - 1, msg.sender, msg.value, challenges, block.number + BET_BLOCK_INTERVAL);

        return true;
    }

    /**
     * @dev 베팅 결과값을 확인 하고 팟머니를 분배한다.
     * 정답 실패 : 팟머니 축척, 정답 맞춤 : 팟머니 획득, 한글자 맞춤 or 정답 확인 불가 : 베팅 금액만 획득
     */
    function distribute() public {
        // head 3 4 5 6 7 8 9 10 11 12 tail
        uint256 cur;
        uint256 transferAmount;

        BetInfo memory b;
        BlockStatus currentBlockStatus;
        BettingResult currentBettingResult;

        for(cur=_head;cur<_tail;cur++) {
            b = _bets[cur];
            currentBlockStatus = getBlockStatus(b.answerBlockNumber);
            // Checkable : block.number > AnswerBlockNumber && block.number  <  BLOCK_LIMIT + AnswerBlockNumber 1
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
                
                // if draw, refund bettor's money 
                if(currentBettingResult == BettingResult.Draw) {
                    // transfer only BET_AMOUNT
                    transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);

                    // emit DRAW
                    emit DRAW(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
            }

            // Not Revealed : block.number <= AnswerBlockNumber 2
            if(currentBlockStatus == BlockStatus.NotRevealed) {
                break;
            }

            // Block Limit Passed : block.number >= AnswerBlockNumber + BLOCK_LIMIT 3
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
    function isMatch(byte challenges, bytes32 answer) public pure returns (BettingResult) {
        // challenges 0xab
        // answer 0xab......ff 32 bytes

        byte c1 = challenges;
        byte c2 = challenges;

        byte a1 = answer[0];
        byte a2 = answer[0];

        // Get first number
        c1 = c1 >> 4; // 0xab -> 0x0a
        c1 = c1 << 4; // 0x0a -> 0xa0

        a1 = a1 >> 4;
        a1 = a1 << 4;

        // Get Second number
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
        if(block.number > answerBlockNumber && block.number  <  BLOCK_LIMIT + answerBlockNumber) {
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

    function pushBet(byte challenges) internal returns (bool) {
        BetInfo memory b;
        b.bettor = msg.sender; // 20 byte
        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL; // 32byte  20000 gas
        b.challenges = challenges; // byte // 20000 gas

        _bets[_tail] = b;
        _tail++; // 32byte 값 변화 // 20000 gas -> 5000 gas

        return true;
    }

    function popBet(uint256 index) internal returns (bool) {
        delete _bets[index];
        return true;
    }
}