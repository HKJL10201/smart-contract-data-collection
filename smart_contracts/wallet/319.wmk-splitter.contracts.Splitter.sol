pragma solidity ^0.4.24;

contract Splitter {

    uint ownerWeis;
    address owner;

    WalletOwner[2] public recipients;

    struct WalletOwner {
        uint balance;
        address holder;
    }

    modifier validEtherSend {
        require(msg.value > 0);
        _;
    }

    event LogSplittedSucceded(uint _weis);
    event LogEtherSended(uint _owner);

    constructor(address _bob, address _carol) public {
        require(msg.sender == owner, "Only owner may call this contract");
        require(_bob != 0);
        require(_carol != 0);
        owner = msg.sender;
        recipients[0].balance = 0;
        recipients[1].balance = 0;
        recipients[0].holder = _bob;
        recipients[1].holder = _carol;
    }

    function sendEther() public validEtherSend payable {
        uint amount = msg.value;
        if (amount % 2 == 0) {
            ownerWeis = 0;
            amount = amount / 2;
        } else {
            ownerWeis = 1;
            amount = (amount - 1) / 2;
        }
        recipients[0].balance += amount;
        recipients[1].balance += amount;
        emit LogEtherSended(amount);
    }
}
