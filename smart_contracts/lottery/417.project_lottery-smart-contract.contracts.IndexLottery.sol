pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";
import "openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "openzeppelin-solidity/contracts/token/ERC20/PausableToken.sol";
import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";

/**
 * @title IndexLottery
 * @dev ERC20 규약을 기본으로, Burnable, Pausable, Destructible 인터페이스로 확장 구현
 *
 */
contract IndexLottery is BurnableToken, PausableToken, Destructible {

  using SafeMath for uint256;

  /**
	 * @dev 지급 계약
	 */
  LotteryPayment public lotteryPayment;

  /**
	 * @dev 생성자 : 복권계약 초기값 설정
	 */
  constructor() public {

    // 지급 계약 생성 : 복권 판매 시간과 별개로 지급 요청 처리하기 위해 분리
    lotteryPayment = new LotteryPayment();

  }

  function getBalance() public view returns(uint256) {
      return  address(this).balance;
  }
  function getThisAddress() public view returns(address) {
      return  address(this);
  }
  
	
/*
===============================================================================================
복권 구매 정보 처리
===============================================================================================
*/

  // 총복권 판매수
  uint256 public totalCount;

  // 복권 현황 : 복권번호 => (구매자 지갑주소 => 수량)
  mapping(string=>mapping(address=>uint256)) private lotMap;
  mapping(string=>address[])                 private lotKey; // 복권번호별 구매자
//  mapping(string=>mapping(uint256=>address)) public lotKey;
  mapping(string=>uint256)                   private lotTot; // 복권번호별 총구매수

  // 구매자 현황 : 구매자 지갑주소 => (복권번호 => 수량)
  mapping(address=>mapping(string=>uint256)) private custMap;
  mapping(address=>string[])                 private custKey; // 구매자별 복권번호
  
  /**
    * @dev 복권 구매 정보 처리
    * @param lotData 구매 복권번호
    * @param customer 구매자 지갑 주소
    * @param lotCnt 구매 복권 매수
    */
  function regist(string lotData, address customer, uint256 lotCnt) public whenNotPaused {

      // 1. 복권 현황 저장

      // 1.1 복권번호별 구매자 저장
      /*
      if (lotMap[lotData][customer] == 0) {
        //lotKey[lotData].push(customer);
        uint256 idx = lotKey[lotData].length - 1;
        idx = idx < 0 ? 0 : idx;
        lotKey[lotData][idx] = customer;
      }
      */
      // 1.2 복권번호별 매수 저장
      lotMap[lotData][customer] = lotMap[lotData][customer].add(lotCnt);

      // 1.3 복권번호별 누적 매수 저장
      lotTot[lotData] = lotTot[lotData].add(lotCnt);

      // 2. 총 판매수 저장
      totalCount = totalCount.add(lotCnt);

      // 3. 구매자 현황 저장
      // 3.1 구매자별 복권번호 저장
      if (custMap[customer][lotData] == 0) {
        custKey[customer].push(lotData);
      }
      // 3.2 구매자별 매수 저장
      custMap[customer][lotData] = custMap[customer][lotData].add(lotCnt);

    }

	function getLotCnt(string lotData, address customer) public view returns(uint256 cnt) {
		return lotMap[lotData][customer];
	}
    /**
      * @dev 해당 복권 번호의 구매자 리스트를 조회한다.
      * @param lotData 구매 복권번호
      * @return 구매자 리스트
      */
  //  function getCustomers(string lotData) public view returns(address[]) {
  //    return lotKey[lotData];
  //  }

    /**
      * @dev 해당 구매자의 복권번호 리스트를 조회한다.
      * @param customer 구매자 지갑 주소
      * @return 복권번호 리스트
      */
  //  function getLotNumbers(address customer, uint256 idx) public view returns(string) {
  //    return custKey[customer][idx];
  //  }

/*
===============================================================================================
복권 구매
===============================================================================================
*/

  // 복권 단가 (고정) : 0.02	Ether 고정. 수수료 및 당첨금의 재원.
  uint256 constant public UNIT_PRICE = 20000000000000000;
  // 단위 수수료
  // TOOD GasPrice 측정 및 통계를 통한 추정 필요 => web3.estimateGas (UI에서)
  uint256 constant public UNIT_FEE  =  2000000000000000;
  // 단위 배당금
  uint256 constant public UNIT_BASE = 18000000000000000;
  event LogFallback(address who, uint256 amt);
  
  /*
   * @dev Fallback 함수
   */
  function() public payable isValidPay() {

    buyLottery(msg.value, string(msg.data), msg.sender);
        
    emit LogFallback(msg.sender, msg.value);

  }

  event LogBuyLottery(address customer, uint256 amt, string lotData, uint256 lotCnt);
  event LogStr(string log);
  
  /*
   * @dev 복권 구매
   */
  function buyLottery(uint256 amt, string lotData, address customer) public payable whenNotPaused returns(uint256 cnt) {

    // 복권 구매 매수 계산
    uint256 lotCnt = amt.div(UNIT_PRICE);

    // 복권 현황 등록
    regist(lotData, customer, lotCnt);
	
	
    emit LogBuyLottery(customer, amt, lotData, lotCnt);
	
	return lotCnt;

  }

  /**
   * @dev 복권번호 필수 입력, 복권구매수 체크
   */
  modifier isValidPay() {

    // 복권 관리자
    if (msg.sender == owner) {
        // 서비스 유지비 입금액 체크
        require(msg.value >= UNIT_FEE, "서비스 유지비 입금 부족");
    // 복권 구매자
    } else {
        require(msg.data.length == 4, "유효한 복권번호 형식이 아닙니다.");
    }
      
    require(msg.value != 0, "입금은 필수입니다.");
    
    require(msg.value % UNIT_PRICE == 0, "유효한 단위로 입금해주세요.");
    
  	_;
  }

/*
===============================================================================================
복권 추첨 로직
===============================================================================================
*/

  // 이월 금액
  uint256 public forwardAmt;

  /**
   * @dev 복권 당첨번호 계산
   * @param index1 KOSPI 지수
   * @param index2 KOSDAQ 지수
   * @return 당첨번호
   */
  function calcLotData(string index1, string index2) public pure returns(string) {
    bytes memory strBytes1 = bytes(index1);
    bytes memory strBytes2 = bytes(index2);
    bytes memory result = new bytes(4);
    result[0] = strBytes1[strBytes1.length - 2];
    result[1] = strBytes1[strBytes1.length - 1];
    result[2] = strBytes2[strBytes2.length - 2];
    result[3] = strBytes2[strBytes2.length - 1];
    return string(result);
  }
  
  string public drawNumber;
  /**
   * @dev 복권 추첨
   * @param index1 KOSPI 지수
   * @param index2 KOSDAQ 지수
   */
  function setDrawNumber(string index1, string index2) public {
      require(bytes(drawNumber).length == 0, "");
      // 당첨번호 계산
      drawNumber = calcLotData(index1, index2);
  }

  event LogDrawLot(string drawNumber, uint256 totalAmount, uint256 hitCount, uint256 forwardAmt);
  
  /**
   * @dev 복권 추첨
   *      당첨자 선정 및 지급 계약 이체
   */
   function settleAccount() public whenPaused {

    // 당첨번호 계산
    require(bytes(drawNumber).length != 0, "");

    // 총모금액 = 총복권 판매수 * 단위 배당금
    uint256 totalAmount = totalCount.mul(UNIT_BASE);

    // 당첨번호가 존재하는 경우
    // 해당 Wallet주소 단위의 배당금을 계산
    // 지급 계약으로 배당금을 이체

    // 총당첨갯수 = 당첨번호에 속한 복권갯수
    uint256 hitCount = lotTot[drawNumber];
    if (hitCount > 0) {

      // 배당단위금액 = 총모금액/총당첨갯수
      uint256 dividendUnit = totalCount.mul(UNIT_BASE).div(hitCount);

      // 단수금액 = 총모금액 - (총복권 판매수 * 배당단위금액)
      uint256 breakAmount = totalAmount.sub(totalCount.mul(dividendUnit));

      // 지급계약으로 전송
      //mapping(address=>uint256) dividendMap;
      uint256 len = lotKey[drawNumber].length;
      address[] memory customers = new address[](len);
      uint256[] memory divAmts   = new uint256[](len);
      for ( uint256 k = 0 ; k < len ; k++ ) {

        address toAddr = lotKey[drawNumber][k];
        customers[k] = toAddr;

        // 배당 금액 계산
        uint256 calcAmt = lotMap[drawNumber][toAddr].mul(dividendUnit);

        // 단수 처리 : 첫번째 입금 계좌에 추가
        if (k == 0) calcAmt = calcAmt.add(breakAmount);

        //dividendMap[toAddr] = calcAmt;
        divAmts[k] = calcAmt;

      }

      // 지급 계약에 모금액 및 배당 정보 전송 (PausableToken)
      lotteryPayment.booking(customers, divAmts);
      //require(lotteryPayment.booking(customers, divAmts));
      require(transfer(lotteryPayment, totalAmount));

    // 당첨번호가 존재하지 않는 경우 : 이월 정보 저장
    } else {

      forwardAmt = totalCount.mul(UNIT_BASE);

    }

    emit LogDrawLot(drawNumber, totalAmount, hitCount, forwardAmt);
    
    drawNumber = "";

  }

}




/**
 * @title LotteryPayment
 * @dev 지급 관리 계약
 *      복권과 1 : 1 매핑 구조
 *
 */
contract LotteryPayment is BurnableToken, MintableToken, PausableToken {

  using SafeMath for uint256;


  /**
    * @dev 지급 대상 복권
    */
  address lottery;

  /**
    * @dev 지급 장부
    */
  mapping(address=>uint256) dividendMap;


  /**
	 * @dev 생성자 : 복권계약 초기값 설정
	 */
  constructor() public {
    lottery = msg.sender;
  }


  event LogBooking(string log, address[] customers, uint256[] divAmts);
  function booking(address[] customers, uint256[] divAmts) external verifyLottery {

    for(uint256 k = 0; k < customers.length; k++) {
      address customer = customers[k];
      uint256 divAmt   = divAmts[k];
      dividendMap[customer] = dividendMap[customer].add(divAmt);
    }

    emit LogBooking("지급 장부 기록 완료", customers, divAmts);

  }

  modifier verifyLottery() {
    require(
      lottery == msg.sender,
      "지급 대상이 아닙니다."
    );
    _;
  }

  event LogRequestTransfer(string log, address customer, uint256 amt);
  function requestTransfer() public verifyCustomer() {
    address customer = msg.sender;
    uint256 amt = dividendMap[customer];
    // 지급 수행
    require(transfer(customer, amt));
    // 장부에서 삭제
    delete dividendMap[customer];
    emit LogRequestTransfer("지급 요청 처리 완료.", customer, amt);
  }
  modifier verifyCustomer() {
    require(
      dividendMap[msg.sender] == 0,
      "지급 대상이 아닙니다."
    );
    _;
  }

  function getCustomerAmount(address customer) public view returns(uint256) {
    return dividendMap[customer];
  }

}
