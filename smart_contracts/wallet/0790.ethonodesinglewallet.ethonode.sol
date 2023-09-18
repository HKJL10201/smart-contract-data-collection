pragma solidity 0.4.23;

contract NodeLender {

    address public lender;
    address public borrower;

    uint public paymentThreshold;
    uint public lenderSplit;
    uint public borrowerTxAllowance;
    
    event logSender(address senderAddress);
    event logReceiver(address receiverAddress);

    constructor() public {
        lender = msg.sender;
        borrower = msg.sender;
        lenderSplit = 100;
        paymentThreshold = 100;
        borrowerTxAllowance = 5;
    }

    function() payable external {
        if(msg.value < (paymentThreshold * (1 ether))) {
            uint lenderPayment = (msg.value / 100) * lenderSplit;
            uint borrowerPayment = (msg.value - lenderPayment);
            lender.transfer(lenderPayment);
            borrower.transfer(borrowerPayment);
        }
    }

    // transfer allows owner to transfer any remaining contract balance(ie node collateral) - value is in wei
    function transfer(address to, uint value) public onlyLender returns (bool) {
        assert(address(this).balance >= value);
        to.transfer(value);
        return true;
    }
    
    // sendVerificationTx allows owner to send a tx to verify node (must be less than 1 etho) - value is in wei
    function sendVerificationTx(address to) public onlyBorrower returns (bool) {
        uint value = 1;
        assert(address(this).balance >= value && value < (1 ether) && borrowerTxAllowance > 0);
        borrowerTxAllowance--;
        to.transfer(value);
        emit logSender(address(this));
        emit logReceiver(to);
        return true;
    }

    // updateTxAllowance allows owner to allocate more contract tranfers
    function updateTxAllowance(uint allowance) public onlyLender() {
        borrowerTxAllowance = allowance;
    }
    
    function updateThreshold(uint threshold) public onlyLender() {
        paymentThreshold = threshold;
    }

    function withdraw() public onlyLender() {
        lender.transfer(address(this).balance);
    }

    function updateLender(address newLender) public onlyLender() {
        lender = newLender;
    }

    function updateBorrower(address newBorrower) public onlyLender() {
        borrower = newBorrower;
    }

    modifier onlyLender {
        require(
            msg.sender == lender
        );
        _;
    }

    modifier onlyBorrower {
        require(
            msg.sender == borrower
        );
        _;
    }

    modifier lenderOrBorrower() {
        require(
            msg.sender == lender || msg.sender == borrower
        );
        _;
    }

}
