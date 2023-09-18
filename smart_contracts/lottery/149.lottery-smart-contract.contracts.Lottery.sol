pragma solidity ^0.8.0;

contract Lottery{
    struct BetInfo{
        uint256 answerBlockNumber; //정답블락
        address payable better; //베팅한사람. 특정 주소한테 돈 보내려면 payable을 써줘야함
        bytes challenges; //ex) 0xab같은 1바이트 값
    }

  uint256 private _tail;
  uint256 private _head;
  mapping(uint256 => BetInfo) private _bets; //Queue역할
  address public owner; //public쓰면 자동으로 getter 만들어줌

  uint constant internal BLOCK_LIMIT = 256;
  uint constant internal BET_BLOCK_INTERVAL = 3;
  uint256 constant internal BET_AMOUNT = 5 * 10 ** 15;
  uint256 private _pot;

  //   truffle을 사용해 contract와 상호작용 확인
  constructor() {
    owner = msg.sender;
  }

  function getSomeValue() public pure returns (uint256 value){
    return 5;
  }

//컨트랙트에 있는 변수를 조회하기위해서는 view사용
  function getPot() public view returns(uint256 pot){
    return _pot;
  }
}