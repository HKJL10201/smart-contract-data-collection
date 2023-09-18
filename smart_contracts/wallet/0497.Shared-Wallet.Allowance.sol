import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Allowance is Ownable {
    
    struct Action {
        int Value;
        uint timestamps;
    }
    
    struct Wallet {
        mapping(uint => Action) payments_withdrawals;
        uint TotalBalance;
        uint numActions;
    }
    
    mapping(address => Wallet) walletBalance;
    
    event allowanceChanged(address indexed _forWho, address indexed _byWhom, uint _oldAmount, uint _newAmount);
    
    modifier OwnerOrAllowed(uint _amount) {
        require(isOwner() || walletBalance[msg.sender].TotalBalance >= _amount,"You do not have permission.");
        _;
    }
    
    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }
    
    function setAllowance(address _to, uint _amount) public payable onlyOwner {
        emit allowanceChanged(_to, msg.sender, walletBalance[_to].TotalBalance, _amount);
        walletBalance[_to].TotalBalance = _amount;
    }
    
    function increaseAllowance(address _to, uint _amount) public payable onlyOwner {
        emit allowanceChanged(_to, msg.sender, walletBalance[_to].TotalBalance, walletBalance[_to].TotalBalance + _amount);
        receivePayment(_to,_amount);
    }
    
    function receivePayment(address _to, uint _amount) internal{
        walletBalance[_to].TotalBalance += _amount;
        walletBalance[_to].payments_withdrawals[walletBalance[_to].numActions].Value = int(_amount);
        walletBalance[_to].payments_withdrawals[walletBalance[_to].numActions].timestamps = block.timestamp;
        walletBalance[_to].numActions += 1;
    }
    
    function reduceAllowance(address _who, uint _amount) internal {
        emit allowanceChanged(_who, msg.sender, walletBalance[_who].TotalBalance, walletBalance[_who].TotalBalance - _amount);
        walletBalance[_who].TotalBalance -= _amount;
        walletBalance[_who].payments_withdrawals[walletBalance[_who].numActions].Value = -int(_amount);
        walletBalance[_who].payments_withdrawals[walletBalance[_who].numActions].timestamps = block.timestamp;
        walletBalance[_who].numActions += 1;
    }
    
    function seeBalance(address _address) public view returns(uint) {
        return walletBalance[_address].TotalBalance;
    }
}
