contract TestWalletDonation {
    address owner;
    address payable thisAddress;
    uint minPercentage;
    uint simulatedVotingFee = 1 ether;
    address constant private _simulatedFeeAddress = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

    uint public _aid;

    event gasEvent(uint aidAmount);

    constructor (uint _minPercentage) {
        owner = msg.sender;
        thisAddress = payable(address(this));
        minPercentage = _minPercentage;
    }
    function fundVoter(uint amount) public view returns(uint) {
        uint minAmount = minPercentage * simulatedVotingFee / 100;
        if (amount >= minAmount) {
            return minAmount;
        }
        return 0;
    }
    function AidVoter() public view returns(uint) {
        if (minPercentage != 0)
            return minPercentage * simulatedVotingFee / 100;
        return 0;
    }

    // We would expect spents to be lower if function payWithAid()
    // is used.

    function payWithoutAid() public payable returns(bool) {
        // Simulate a vote. We are only interested in spents.
        //bool status = vote();
        (bool status, ) = _simulatedFeeAddress.call{value: simulatedVotingFee}("");
        require(status, "Vote failed");
        return status;
    }
    function payWithAid(address payable to) public payable returns(uint) {
        // Simulate a vote. We are only interested in spents.
        //bool status = vote();
        (bool status, ) = _simulatedFeeAddress.call{value: simulatedVotingFee}("");
        require(status, "Vote failed");
        // Generate aid amount
        //uint aid = AidVoter();
        uint aid;
        if (minPercentage != 0)
            aid = minPercentage * simulatedVotingFee / 100;
        _aid = aid;
        // Pay aid amount back to voter
        (status, ) = to.call{value: aid}("");
        require(status, "Transfer failed");
        return aid;
    }
    
    // Deposit ether in this contract
    function depositToWallet() external payable {
        payable(address(this)).transfer(msg.value);
    }
    function vote() internal returns (bool) {
        (bool status, ) = _simulatedFeeAddress.call{value: simulatedVotingFee}("");
        return status;
    }
    function getBalance(address from) public view returns(uint) {
        return from.balance;
    }
    function setBalanceStart(address from) public {
        _balanceStart = from.balance;
    }
    function setBalanceEnd(address from) public {
        _balanceEnd = from.balance;
    }
    function getBalanceDiff() public view returns(uint){
        return _balanceStart -_balanceEnd;
    }
    function setBalanceTest(address from) public view returns(uint){
        return getBalance(from) + _aid;
    }
    receive() external payable {}
    fallback() external payable {}
}
