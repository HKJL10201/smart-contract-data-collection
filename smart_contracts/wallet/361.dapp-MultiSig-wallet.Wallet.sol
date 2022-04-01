pragma solidity 0.7.5;
pragma abicoder v2;
import "./Ownable.sol";
import "./Destroyable.sol";

contract MultiSigWallet is Ownable, Destroyable {

    address[] public owners;
    uint n;

    struct TxRequest {
        uint txId;
        address payable receiver;
        uint amount;
        uint confirmations;
        bool ifSent;
    }

    event TransferRequestCreated(uint _id, uint _amount, address _initiator, address _receiver);
    event ApprovalReceived(uint _id, uint _confirmations, address _approver);
    event TransferApproved(uint _id);

    TxRequest[] requests;

    mapping(address => mapping(uint => bool)) approvals;

    modifier ownersOnly() {
        bool answer = false;
        for (uint i=0; i < owners.length; i++){
            if(owners[i] == msg.sender){
                answer = true;
                break;
            }
            else {
                answer = false;
            }
        }
        require(answer == true);
        _;
    }

    constructor(address[] memory _owners, uint _n){
        owners = _owners;
        n = _n;
    }

    mapping(address => uint) balances;

    function addOwner(address _newAddress) private onlyOwner {
        owners.push(_newAddress);
    }

    function updateLimit(uint _n) private onlyOwner {
        require(_n <= owners.length);
        n = _n;
    }

    function deposit(uint _amount) public payable {
        balances[msg.sender] += _amount;
    }

    function createTransfer(uint _amount, address payable _receiver) public ownersOnly{
        requests.push(TxRequest(requests.length, _receiver, _amount, 0, false));

        emit TransferRequestCreated(requests.length - 1, _amount, msg.sender, _receiver);
    }

    function approve(uint _idApproval) public ownersOnly{
        require(approvals[msg.sender][_idApproval] == false);
        require(requests[_idApproval].ifSent = false);

        approvals[msg.sender][_idApproval] = true;
        requests[_idApproval].confirmations += 1;
        if(requests[_idApproval].confirmations >= n){
            requests[_idApproval].ifSent = true;
            requests[_idApproval].receiver.transfer(requests[_idApproval].amount);
            emit TransferApproved(_idApproval);
        }
        emit ApprovalReceived(_idApproval, requests[_idApproval].confirmations, msg.sender);
    }

    function getAllRequests() public view returns(TxRequest[] memory){
        return requests;
    }
}
