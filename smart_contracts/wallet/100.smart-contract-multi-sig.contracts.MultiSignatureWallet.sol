pragma solidity ^0.4.18;

contract MultiSignatureWallet {

    address[] public owners;
    uint public signaturesRequired;

    function MultiSignatureWallet(
        address[] owners_,
        uint signaturesRequired_
    )
    public
    {
        owners = owners_;
        signaturesRequired = signaturesRequired_;
    }

    modifier onlyOwner() {
        bool isOwner;
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                isOwner = true;
                break;
            }
        }
        require(isOwner);
        _;
    }

    event NewTransaction(uint transactionId);

    struct Transaction {
        address target;
        uint amount;
        uint confirmations;
    }

    mapping(uint => Transaction) public transactions;
    uint public transactionCount;

    function submitTransaction(
        address target,
        uint amount
    )
    onlyOwner
    public
    returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction(target, amount, 1);
        NewTransaction(transactionId);
        transactionCount++;
    }
}
