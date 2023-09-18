pragma solidity 0.5.16;

contract DTSC{
  address payable public dtc;
  address payable public ds;
  address payable public dp;
  enum DTSCStatus {WaitingforDP, Aborted}
  DTSCStatus public status; 
  enum DPStatus {DPDeposited, SuccessfulTrading, Unsatisfied, DPIsWrong, TradingCompleted, Refunded}
  uint numberOfDPs;
  uint numberOfSuccessfulSales;
  uint public deposit;
  uint public dataprice;

  struct Purchaser{
    DPStatus status;
  }

  mapping (address => Purchaser) public DPs;

  modifier DPCost(){
    require(msg.value == dataprice+deposit);
    _;
  }

  modifier OnlyDTC(){
    require(msg.sender == dtc);
    _;
  }

  modifier OnlyDS(){
    require(msg.sender == ds);
    _;
  }

  modifier OnlyDP(){
    require(msg.sender == dp);
    _;
  }
  modifier DSCost(){
    require(msg.value == deposit);
    _;
  }

  constructor() public {
    dtc = 0x62b1e832130672CfeD8CAb10c0919993a505b311;
    ds = 0x00225D5aC189405947e027ddd6c5C6CCf9ED8972;
    dp = 0x00bFAA40777963f2324e1f5b3e0f427FEa8f4ac7;
    status = DTSCStatus.WaitingforDP;
    deposit = 3 ether;
    dataprice = 2 ether;    
    numberOfDPs = 0;
    numberOfSuccessfulSales = 0;     
  }
  event DSDeposited(string info,address DS);
  event DPDepositedandPaid(address DP, string info);  
  event successfulTrading(address DP);
  event unsuccessfulTrading(address DP);
  event DTCArbitrationThroughDTCSC(address DP, string info);
  event DPRight(address DP, string info);
  event DPWrong(address DP, string info);
  event refundDone(address DP);
  event paymentSettled(address DP, string info);
  event RefundBasedOnDPRequest(string info, address DP);

  function RequestSellData() OnlyDS DSCost payable public{
    require(msg.sender == ds);
	emit DSDeposited("Selling data", ds);  
  }
 
  function RequestGetData() OnlyDP DPCost payable public{
    require(status == DTSCStatus.WaitingforDP);
    DPs[msg.sender].status = DPStatus.DPDeposited;
    emit DPDepositedandPaid(msg.sender, "DP deposited and paid for data resource");
    numberOfDPs++;
  }    

  function refund() OnlyDP public{
    require(DPs[msg.sender].status == DPStatus.DPDeposited);
    uint x = deposit+dataprice;
    msg.sender.transfer(x);
    DPs[msg.sender].status = DPStatus.Refunded;
    emit RefundBasedOnDPRequest("DP has been refunded", msg.sender);
  }  
    
  function ConfirmResult(bool result) OnlyDP public{
    require (DPs[msg.sender].status == DPStatus.DPDeposited);
    if(result){
      emit successfulTrading(msg.sender);
      DPs[msg.sender].status = DPStatus.SuccessfulTrading;
      settlepayment(msg.sender);
    }
    else{
      emit unsuccessfulTrading(msg.sender);
      DPs[msg.sender].status = DPStatus.Unsatisfied;
      emit DTCArbitrationThroughDTCSC(msg.sender, "DTC is involved in dispute arbitration.");
    }      
  }
  
  function SettleDisputeAndPayment(address payable DP, bool result) OnlyDTC public{
    require(DPs[DP].status == DPStatus.Unsatisfied);
    if(result){
      emit DPRight(DP, "DP should be refunded");
      DP.transfer(dataprice+deposit);
      dtc.transfer(deposit);
      emit refundDone(DP);
      DPs[DP].status = DPStatus.TradingCompleted;
    }
    else{
      emit DPWrong(DP, "DP is Wrong.");
	  DPs[DP].status = DPStatus.DPIsWrong;
      settlepayment(DP);           
    }
  }
  
  function settlepayment(address payable DP) internal{
    require(DPs[DP].status == DPStatus.SuccessfulTrading || DPs[DP].status == DPStatus.DPIsWrong);
    uint x = dataprice/2;
    uint dsincome = deposit + x;
    ds.transfer(dsincome);
    dtc.transfer(x);
    DP.transfer(deposit);
    emit paymentSettled(DP, "Payment settled");
    DPs[DP].status = DPStatus.TradingCompleted;
  }    
}