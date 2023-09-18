pragma solidity ^0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./HouseToken.sol";


contract MortgageContract { 
	
	function getPropertyTokenAddress() public view returns (address) {
		return address(propertyToken);
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}


	int Gateway_1whiz9yIncoming = 0;

	mapping(string => bool) public Process_1ActiveStates;

	mapping(string => address) public addressMapping;

	HouseToken public propertyToken;

	MortgageCancellation public mortgageCancellation;

	Insurance public insurance;

	Mortgage public mortgage;

	bool public termsViolated;

	uint public contractValidDate;

	string public mortgageDefaultRequest;

	bool public lenderAgreed;

	bool public isIndemnityValid;

	bool public mortgageCompleted;

	bool public isContractCancelable;

	bool public ownerAgreed;

	struct Mortgage{
		uint256 propertyId;
		uint256 propertyPrice;
		uint256 rate;
		uint256 downPaymentValue;
		uint256 mortgageDurationMonths;
		uint256 totalPaid;
		Payment[] payments;
	}

	struct Insurance{
		bool isEnsured;
		string additionalInformation;
	}

	struct MortgageCancellation{
		string reason;
		bool confirmation;
	}

	struct Payment{
		uint256 amount;
		uint paymentDateTime;
		address sender;
		bool onSchedule;
	}

	function isStateActiveProcess_1(string memory state) public view returns(bool){
		return Process_1ActiveStates[state];
	}

	function getRoleAddress(string memory role) public view returns(address) {
		return addressMapping[role];
	}

	constructor(address propertyTokenAddress) public payable{
		propertyToken = HouseToken(propertyTokenAddress);
		Process_1ActiveStates["ApplyForaMortgagePayable"] = true;
	}

	modifier isApplyForaMortgagePayableState{
		require(isStateActiveProcess_1("ApplyForaMortgagePayable") == true);
		_;
	}

	modifier isApplyForaMortgagePayableAuthorized{
		if(addressMapping["Borrower"] == address(0x0)){
			addressMapping["Borrower"] = msg.sender;
		}
		require(msg.sender==addressMapping["Borrower"]);
		_;
	}

	function ApplyForaMortgagePayable(uint256 propertyId, uint256 propertyPrice, uint256 rate, uint256 mortgageDurationMonths) payable isApplyForaMortgagePayableState() isApplyForaMortgagePayableAuthorized() public {
		mortgage.propertyId = propertyId;
		mortgage.propertyPrice = propertyPrice;
		mortgage.rate = rate;
		mortgage.downPaymentValue = msg.value;
		mortgage.mortgageDurationMonths = mortgageDurationMonths;
    	isContractCancelable = true;
          
		Process_1ActiveStates["ApplyForaMortgagePayable"] = false;
		Gateway_0dznqqs();
	}

	function Gateway_1ps7u6w() internal {
		Process_1ActiveStates["EscrowPropertyRights"] = true;
		Process_1ActiveStates["AcceptInsurance"] = true;
		Process_1ActiveStates["EscrowMoneyPayable"] = true;
	}

	modifier isAcceptInsuranceState{
		require(isStateActiveProcess_1("AcceptInsurance") == true);
		_;
	}

	modifier isAcceptInsuranceAuthorized{
		if(addressMapping["Insurer"] == address(0x0)){
			addressMapping["Insurer"] = msg.sender;
		}
		require(msg.sender==addressMapping["Insurer"]);
		_;
	}

	function AcceptInsurance(string memory notes) isAcceptInsuranceState() isAcceptInsuranceAuthorized() public {
		insurance.isEnsured = true;
		insurance.additionalInformation = notes;
		Process_1ActiveStates["AcceptInsurance"] = false;
		Gateway_1whiz9y();
	}

	modifier isEscrowPropertyRightsState{
		require(isStateActiveProcess_1("EscrowPropertyRights") == true);
		_;
	}

	modifier isEscrowPropertyRightsAuthorized{
		if(addressMapping["Property Owner"] == address(0x0)){
			addressMapping["Property Owner"] = msg.sender;
		}
		require(msg.sender==addressMapping["Property Owner"]);
		_;
	}

	function EscrowPropertyRights() isEscrowPropertyRightsState() isEscrowPropertyRightsAuthorized() public {
		require(propertyToken.getApproved(mortgage.propertyId) == address(this));
	    require(propertyToken.ownerOf(mortgage.propertyId) == msg.sender);
	    propertyToken.transferFrom(msg.sender, address(this), mortgage.propertyId);
	    ownerAgreed = true;
		Process_1ActiveStates["EscrowPropertyRights"] = false;
		Gateway_1whiz9y();
	}

	modifier isEscrowMoneyPayableState{
		require(isStateActiveProcess_1("EscrowMoneyPayable") == true);
		_;
	}

	modifier isEscrowMoneyPayableAuthorized{
		if(addressMapping["Lender"] == address(0x0)){
			addressMapping["Lender"] = msg.sender;
		}
		require(msg.sender==addressMapping["Lender"]);
		_;
	}

	function EscrowMoneyPayable() payable isEscrowMoneyPayableState() isEscrowMoneyPayableAuthorized() public {
		require(msg.value == mortgage.propertyPrice - mortgage.downPaymentValue);
		lenderAgreed = true;
		Process_1ActiveStates["EscrowMoneyPayable"] = false;
		Gateway_1whiz9y();
	}

	function Gateway_1whiz9y() internal {
		Gateway_1whiz9yIncoming += 1;
		if(Gateway_1whiz9yIncoming==3){
			PayOwnerPayment();
			Gateway_1whiz9yIncoming = 0;
		}
	}

	function ReleaseEscrows() internal {
		if(lenderAgreed)
            payable(addressMapping["Lender"]).transfer(mortgage.propertyPrice - mortgage.downPaymentValue);
        if(ownerAgreed)
            propertyToken.transferFrom(address(this),addressMapping["Property Owner"], mortgage.propertyId);
        payable(addressMapping["Borrower"]).transfer(mortgage.downPaymentValue);
		Process_1ActiveStates["ContractCancelled"] = true;
	}

	modifier isCancelApplicationState{
		require(isStateActiveProcess_1("CancelApplication") == true);
		_;
	}

	modifier isCancelApplicationAuthorized{
		if(addressMapping["Borrower"] == address(0x0)){
			addressMapping["Borrower"] = msg.sender;
		}
		require(msg.sender==addressMapping["Borrower"]);
		_;
	}

	function CancelApplication(string memory reason) isCancelApplicationState() isCancelApplicationAuthorized() public {
		mortgageCancellation.reason = reason;
		Process_1ActiveStates["CancelApplication"] = false;
		Gateway_1wbe662();
	}

	function PayOwnerPayment() internal {
		payable(addressMapping["Property Owner"]).transfer(mortgage.propertyPrice);
		contractValidDate = now;
		Process_1ActiveStates["CancelApplication"] = false;//
		isContractCancelable = false;//
		Gateway_1b1r7rx();
	}

	function Gateway_1egt0pj() internal {
		Process_1ActiveStates["PayMortgageFeePayable"] = true;
	}

	function Gateway_1b1r7rx() internal {
		Gateway_1egt0pj();
		Gateway_1rnm0w1();
	}

	modifier isRequestDefaultState{
		require(isStateActiveProcess_1("RequestDefault") == true);
		_;
	}

	modifier isRequestDefaultAuthorized{
		if(addressMapping["Lender"] == address(0x0)){
			addressMapping["Lender"] = msg.sender;
		}
		require(msg.sender==addressMapping["Lender"]);
		_;
	}

	function RequestDefault(string memory reason) isRequestDefaultState() isRequestDefaultAuthorized() public {
		mortgageDefaultRequest = reason;
		Process_1ActiveStates["RequestDefault"] = false;
		ValidateTermsViolation();
	}

	function Gateway_1rnm0w1() internal {
		Process_1ActiveStates["RequestDefault"] = true;
	}

	function ValidateTermsViolation() internal {
		uint lastPaymentDate;
		if(mortgage.payments.length == 0)
		    lastPaymentDate = contractValidDate;
		else
		    lastPaymentDate = mortgage.payments[mortgage.payments.length-1].paymentDateTime;
		if(now - lastPaymentDate > 5274000)
		    termsViolated = true;
		Gateway_1c0jk30();
	}

	function Gateway_1c0jk30() internal {
		if(!termsViolated){
			Gateway_1rnm0w1();
		}
		else if(termsViolated){
			Process_1ActiveStates["TransferProportionMoneytotheBorrowerPayable"] = true;
		}
	}

	function TransferthePropertytotheLender() internal {
		propertyToken.transferFrom(address(this),addressMapping["Lender"], mortgage.propertyId);
		Process_1ActiveStates["LoanDefaulted"] = true;
	}

	modifier isPayMortgageFeePayableState{
		require(isStateActiveProcess_1("PayMortgageFeePayable") == true);
		_;
	}

	modifier isPayMortgageFeePayableAuthorized{
		if(addressMapping["Borrower"] == address(0x0)){
			addressMapping["Borrower"] = msg.sender;
		}
		require(msg.sender==addressMapping["Borrower"]);
		_;
	}

	function PayMortgageFeePayable() payable isPayMortgageFeePayableState() isPayMortgageFeePayableAuthorized() public {
		mortgage.totalPaid += msg.value;
        mortgage.payments.push(Payment(msg.value, now, msg.sender, true));
		Process_1ActiveStates["PayMortgageFeePayable"] = false;
		PaymenttotheInsurerandLender();
	}

	function CheckPaymentSchedule() internal {
		uint256 monthlyFee = (mortgage.propertyPrice - mortgage.downPaymentValue)*(1+mortgage.rate/100)/mortgage.mortgageDurationMonths;
        Payment storage lastPayment = mortgage.payments[mortgage.payments.length-1];
        if (lastPayment.amount < monthlyFee) {
            lastPayment.onSchedule = false; 
        } 
        else {
            lastPayment.onSchedule = true; 
        }
          
		Gateway_04v6h62();
	}

	function Gateway_04v6h62() internal {
		if(mortgage.totalPaid >=(mortgage.propertyPrice - mortgage.downPaymentValue)*(1+mortgage.rate/100)){
			TransferthePropertytotheBorrower();
		}
		else if(mortgage.totalPaid < (mortgage.propertyPrice - mortgage.downPaymentValue)*(1+mortgage.rate/100)){
			Gateway_1wj3ze2();
		}
	}

	function TransferthePropertytotheBorrower() internal {
		propertyToken.transferFrom(address(this),addressMapping["Borrower"], mortgage.propertyId);
		Process_1ActiveStates["RequestDefault"] = false;
		Process_1ActiveStates["LoanCompleted"] = true;		
		mortgageCompleted = true;
	}

	modifier isCheckIndemnityTermsState{
		require(isStateActiveProcess_1("CheckIndemnityTerms") == true);
		_;
	}

	modifier isCheckIndemnityTermsAuthorized{
		if(addressMapping["Insurer"] == address(0x0)){
			addressMapping["Insurer"] = msg.sender;
		}
		require(msg.sender==addressMapping["Insurer"]);
		_;
	}

	function CheckIndemnityTerms(bool validity) isCheckIndemnityTermsState() isCheckIndemnityTermsAuthorized() public {
		isIndemnityValid = validity;
		Process_1ActiveStates["CheckIndemnityTerms"] = false;
		Gateway_04bakm7();
	}

	function Gateway_04bakm7() internal {
		if(isIndemnityValid){
			Process_1ActiveStates["PayfortheBorrowerPayable"] = true;
		}
		else if(!isIndemnityValid){
			Gateway_1egt0pj();
		}
	}

	modifier isPayfortheBorrowerPayableState{
		require(isStateActiveProcess_1("PayfortheBorrowerPayable") == true);
		_;
	}

	modifier isPayfortheBorrowerPayableAuthorized{
		if(addressMapping["Insurer"] == address(0x0)){
			addressMapping["Insurer"] = msg.sender;
		}
		require(msg.sender==addressMapping["Insurer"]);
		_;
	}

	function PayfortheBorrowerPayable() payable isPayfortheBorrowerPayableState() isPayfortheBorrowerPayableAuthorized() public {
		uint256 monthlyFee = (mortgage.propertyPrice - mortgage.downPaymentValue)*(1+mortgage.rate/100)/mortgage.mortgageDurationMonths;
		require(msg.value == monthlyFee - mortgage.payments[mortgage.payments.length-1].amount);
		mortgage.payments.push(Payment(msg.value, now, msg.sender, true));
		mortgage.totalPaid += msg.value;
		Process_1ActiveStates["PayfortheBorrowerPayable"] = false;
		ProcessInsurerPayment();
	}

	function PaymenttotheInsurerandLender() internal {
		uint256 amountToLender = mortgage.payments[mortgage.payments.length-1].amount*95/100;
        payable(addressMapping["Lender"]).transfer(amountToLender);
        payable(addressMapping["Insurer"]).transfer(mortgage.payments[mortgage.payments.length-1].amount - amountToLender);
          
		CheckPaymentSchedule();
	}

	modifier isTransferProportionMoneytotheBorrowerPayableState{
		require(isStateActiveProcess_1("TransferProportionMoneytotheBorrowerPayable") == true);
		_;
	}

	modifier isTransferProportionMoneytotheBorrowerPayableAuthorized{
		if(addressMapping["Lender"] == address(0x0)){
			addressMapping["Lender"] = msg.sender;
		}
		require(msg.sender==addressMapping["Lender"]);
		_;
	}

	function TransferProportionMoneytotheBorrowerPayable() payable isTransferProportionMoneytotheBorrowerPayableState() isTransferProportionMoneytotheBorrowerPayableAuthorized() public {
		require(msg.value == mortgage.totalPaid); //simplified
		payable(addressMapping["Borrower"]).transfer(address(this).balance);
		Process_1ActiveStates["TransferProportionMoneytotheBorrowerPayable"] = false;
		TransferthePropertytotheLender();
	}

	function Gateway_0dznqqs() internal {
		Gateway_1ps7u6w();
		Process_1ActiveStates["CancelApplication"] = true;
	}

	function Gateway_1wbe662() internal {
		if(isContractCancelable){
			ReleaseEscrows();
		}
		else if(!isContractCancelable){
			Process_1ActiveStates["CancelApplication"] = true;
		}
	}

	function Gateway_1wj3ze2() internal {
		if(!mortgage.payments[mortgage.payments.length-1].onSchedule){
			Process_1ActiveStates["CheckIndemnityTerms"] = true;
		}
		else if(mortgage.payments[mortgage.payments.length-1].onSchedule){
			Gateway_1egt0pj();
		}
	}

	function ProcessInsurerPayment() internal {
		uint256 amountToLender = mortgage.payments[mortgage.payments.length-1].amount*95/100;
        payable(addressMapping["Lender"]).transfer(amountToLender);
        payable(addressMapping["Insurer"]).transfer(mortgage.payments[mortgage.payments.length-1].amount - amountToLender);
          
		Gateway_1egt0pj();
	}

 }