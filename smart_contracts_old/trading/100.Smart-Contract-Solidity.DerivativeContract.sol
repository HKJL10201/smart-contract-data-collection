contract Account{
	    string accountHolderName;
        uint accountNo;
        string accountBankName;
        string ifscCode;
		address owner;

		function Account(string _accountHolderName, uint _accountNo, string _accountBankName, string _ifscCode) {
			owner = msg.sender;
            accountHolderName = _accountHolderName;
            accountNo = _accountNo;
            accountBankName = _accountBankName;
            ifscCode = _ifscCode;

    }

	function getAccountDetails() constant returns(string, uint, string, string) {
        return (accountHolderName,accountNo,accountBankName,ifscCode);
    }

	function() {
	     throw;
	}

	function killAccount() {
        if (msg.sender == owner) {
            suicide(owner);
        }
    }
}




contract Asset {
    string name;
    address masterContractAdd;
    string logo;
    address owner;

    function setAssetName(string assetName) {
        name = assetName;
    }

    function getAssetName() constant returns(string) {
        return name;
    }

    function Asset(string assetName, address _masterContractAdd) {
        name = assetName;
        masterContractAdd = _masterContractAdd;
        owner = msg.sender;
    }

    function setLogo(string _logo) {
        logo = _logo;
    }

    function getLogo() constant returns(string) {
        return logo;
    }

    function getAssetDetails() constant returns(string, string) {
        return (name, logo);

    }

    function killAssets() {
        if (msg.sender == owner) {
            suicide(owner);
        }
    }
	function() {
	     throw;
	}

}

contract Trader {
    address bank;
    string profilePicture;
    string name;
    address masterContractAdd;
    address traderPhysicalAdd;
    address owner;

    function Trader(address bankAddress, string _name, address _masterContractAdd, address _traderPhysicalAdd) {
        bank = bankAddress;
        name = _name;
        masterContractAdd = _masterContractAdd;
        traderPhysicalAdd = _traderPhysicalAdd;
        owner = msg.sender;
    }

    function getBank() constant returns(address) {
        return bank;

    }

    function setProfilePic(string profilePicHash) {
        profilePicture = profilePicHash;
    }

    function getProfilePic() constant returns(string) {
        return profilePicture;
    }

    function getTraderDetails() constant returns(string, string, address) {
        return (name, profilePicture, bank);

    }

    function getTraderPhysicalAdd() constant returns(address) {
        return traderPhysicalAdd;
    }

    function killTraders() {
        suicide(owner);
    }

	function() {
	     throw;
	}

}


contract Bank {
    string name;
    address[] traders;
    address[] derivativeContracts;
    address masterContractAdd;
    string logo;
    address owner;

    function addTrader(address traderAddr) {
        address[] tempTraders = traders;
        tempTraders.push(traderAddr);
    }

    function getTraders() constant returns(address[]) {
        return traders;
    }

    function Bank(string bankName, address _masterContractAdd) {
        name = bankName;
        masterContractAdd = _masterContractAdd;
        owner = msg.sender;
    }

    function addDerivativeContract(address derivativeContractAdd) {
        address[] tempDerivativeContracts = derivativeContracts;
        tempDerivativeContracts.push(derivativeContractAdd);
    }

    function getDerivativeContracts() constant returns(address[]) {
        return derivativeContracts;
    }

    function getAllDetailsOfBank() constant returns(string, address[] bankTraders, address[] derivativeCon, string) {
        return (name, traders, derivativeContracts, logo);
    }

    function setLogo(string _logo) {
        logo = _logo;
    }

    function getLogo() constant returns(string) {
        return logo;
    }

    function killBanks() {
        if (msg.sender == owner) {
            address[] _traders = traders;
            for (uint i = 0; i < _traders.length; ++i) {
                Trader(_traders[i]).killTraders();
            }
            suicide(owner);
        }
    }

	function() {
	     throw;
	}

}

contract DerivativeContract {
    address owner;

    struct response {
        address trader;
        uint currentPremium;
        string responseDocHash;
        uint responseDate;
    }

    string tradeExecutionHash;
    string tradeSettlementHash;

    enum tradeType {
        FUTURE,
        OPTIONS
    }

    enum derivativeContractStatus {
        CLOSED,
        CUSTOMER_SETTLED,
        EXECUTED,
        EXECUTION_PENDING,
        OPEN,
        PENDING,
        SETTLED,
        SETTLEMENT_PENDING,
		TERMINATED,
		PARTIAL_TERMINATION
    }

    enum transactionType {
        BUY,
        SELL
    }

    address asset;

    uint quantity;

    uint expiryDate;

    tradeType derivativeType;

    transactionType transaction;

    address bank;

    derivativeContractStatus status;

    response currentResponse;

    uint premium;

    address customer;

    address customerPhyscialAdd;

    string DerivativeContractHash;

    address masterContractAdd;

    uint requestedDate;

	address customerAccount;

	string rejectionReason;

    function DerivativeContract(address customerAddress, address assetAddress, uint qty, uint derContractExpDate, address bankAddress, uint typeOfTrade, string requestDocHash, address _masterContractAdd, address _customerPhysicalAdd, uint _transactionType,uint _requestedDate) {
        customer = customerAddress;
        asset = assetAddress;
        quantity = qty;
        expiryDate = derContractExpDate;
        bank = bankAddress;
        if (typeOfTrade == 0)
            derivativeType = tradeType.FUTURE;
        else
            derivativeType = tradeType.OPTIONS;
        DerivativeContractHash = requestDocHash;
        status = derivativeContractStatus.OPEN;
        masterContractAdd = _masterContractAdd;
        customerPhyscialAdd = _customerPhysicalAdd;
        requestedDate=_requestedDate;
        if (_transactionType == 0)
            transaction = transactionType.BUY;
        else
            transaction = transactionType.SELL;
        owner = msg.sender;

        MasterContract(masterContractAdd).eventTrigger(customerPhyscialAdd, "REQUEST", now, "OPEN", 0, this, DerivativeContractHash, "raising a request",quantity);
    }

    function responseForDerivativeContract(address traderAddress, uint proposedPremium, string docHash, uint _responseDate) {
        if (status == derivativeContractStatus.OPEN) {
            currentResponse.trader = traderAddress;
            currentResponse.currentPremium = proposedPremium;
            currentResponse.responseDocHash = docHash;
            status = derivativeContractStatus.PENDING;
            currentResponse.responseDate=_responseDate;
            MasterContract(masterContractAdd).eventTrigger(Trader(traderAddress).getTraderPhysicalAdd(), "RESPONSE", now, "PENDING", proposedPremium, this, docHash, "premium is not good",quantity);
        }
    }

    function acceptResponse() {
        premium = currentResponse.currentPremium;
        status = derivativeContractStatus.CLOSED;
        MasterContract(masterContractAdd).eventTrigger(customerPhyscialAdd, "RESPONSE_APPROVAL", now, "CLOSED", premium, this, currentResponse.responseDocHash, "premium is good", quantity);
    }

    function rejectResponse(string _rejectionReason) {
        status = derivativeContractStatus.OPEN;
		rejectionReason=_rejectionReason;
        MasterContract(masterContractAdd).eventTrigger(customerPhyscialAdd, "RESPONSE_REJECTION", now, "OPEN", premium, this, currentResponse.responseDocHash,rejectionReason,quantity);
        delete currentResponse;
    }

	function getRejectionReason() constant returns (string) {
        return rejectionReason;
    }


    function getDerivativeContractDetails() constant returns(address, uint, uint, tradeType, address, derivativeContractStatus,
        uint, address, string, transactionType, uint, string,address) {

        return (asset, quantity, expiryDate, derivativeType, bank, status, premium, customer, DerivativeContractHash,
            transaction, requestedDate, tradeSettlementHash,customerAccount);
    }

    function getResponseForContract() constant returns(address, uint, string, uint) {
        return (currentResponse.trader, currentResponse.currentPremium, currentResponse.responseDocHash, currentResponse.responseDate);
    }

    function killDerivativeContracts() {
        if (msg.sender == owner) {
            suicide(owner);
        }
    }

    function addAccountDetails(address _customerAccount) {
        if (status == derivativeContractStatus.CLOSED) {
            customerAccount=_customerAccount;
            status = derivativeContractStatus.EXECUTION_PENDING;

        }

    }

    function executeTrade(string _tradeExecutionHash) {
        if (status == derivativeContractStatus.EXECUTION_PENDING) {
            status = derivativeContractStatus.EXECUTED;
            tradeExecutionHash = _tradeExecutionHash;
            MasterContract(masterContractAdd).eventTrigger(Trader(currentResponse.trader).getTraderPhysicalAdd(), "TRADE_EXECUTION", now, "EXECUTED", premium, this, tradeExecutionHash, "both parties agreed",quantity);
        }

    }

     function executeTradeByCustomer(string _tradeExecutionHash) {
            tradeExecutionHash = _tradeExecutionHash;
    }

    function getTradeExecutionDocHash() constant returns(string) {
            return tradeExecutionHash;
    }

    function scheduleSettlement() {
        if (status == derivativeContractStatus.EXECUTED) {
            status = derivativeContractStatus.SETTLEMENT_PENDING;
            MasterContract(masterContractAdd).eventTrigger(Trader(currentResponse.trader).getTraderPhysicalAdd(), "SETTLEMENT_PENDING", now, "SETTLEMENT_PENDING", premium, this, tradeExecutionHash, "expiry date reached",quantity);
        }
    }

    function settleTrade(string _tradeSettlementHash) {
        if (status == derivativeContractStatus.SETTLEMENT_PENDING) {
            status = derivativeContractStatus.CUSTOMER_SETTLED;
            tradeSettlementHash = _tradeSettlementHash;
            MasterContract(masterContractAdd).eventTrigger(customerPhyscialAdd, "CUSTOMER_SETTLED", now, "CUSTOMER_SETTLED", premium, this, tradeSettlementHash, "customer agreed to settle",quantity);
        } else if (status == derivativeContractStatus.CUSTOMER_SETTLED) {
            tradeSettlementHash = _tradeSettlementHash;
            status = derivativeContractStatus.SETTLED;
            MasterContract(masterContractAdd).eventTrigger(Trader(currentResponse.trader).getTraderPhysicalAdd(), "TRADE_SETTLED", now, "SETTLED", premium, this, tradeSettlementHash, "both parties agreed to settle",quantity);
        }

    }

	function terminate(uint terminationType , uint _qty) {
		if(status == derivativeContractStatus.EXECUTED){
		if (terminationType == 0) {
			quantity=quantity-_qty;
			MasterContract(masterContractAdd).eventTrigger(customerPhyscialAdd, "PARTIAL_TERMINATION", now, "PARTIAL_TERMINATION", premium, this, tradeExecutionHash, "customer has partially terminated the contract",quantity);
			}
        else
		   {
            status = derivativeContractStatus.TERMINATED;
			MasterContract(masterContractAdd).eventTrigger(customerPhyscialAdd, "TRADE_TERMINATED", now, "TERMINATED", premium, this, tradeExecutionHash, "customer has fully terminated the contract",quantity);
	      }
	    }

	}

	function() {
	     throw;
	}

    function updateRequestDocHash(string _derivativeContractHash){
        DerivativeContractHash=_derivativeContractHash;
    }

}

contract Customer {
    address owner;

    address[] derivativeContracts;
    string profilePicture;
    string name;
    address masterContractAdd;
    address customerPhysicalAdd;
	address[] customerAccounts;

    function createDerivativeContract(address customer, address assetAddress, uint qty, uint derContractExpDate, address bankAddress, uint typeOfTrade, string requestDocHash, uint transactionType,uint _requestedDate) returns(address) {
        address lastCreated = new DerivativeContract(customer, assetAddress, qty, derContractExpDate, bankAddress, typeOfTrade, requestDocHash, masterContractAdd, customerPhysicalAdd, transactionType,_requestedDate);
        address[] tempderivativeContractsList = derivativeContracts;
        tempderivativeContractsList.push(lastCreated);
        Bank(bankAddress).addDerivativeContract(lastCreated);
        return lastCreated;
    }

    function getDerivativeContracts() constant returns(address[]) {
        return derivativeContracts;
    }

    function setProfilePic(string profilePicHash) {
        profilePicture = profilePicHash;
    }

    function getProfilePic() constant returns(string) {
        return profilePicture;
    }

    function Customer(string _name, address _masterContractAdd, address _customerPhysicalAdd) {
        name = _name;
        masterContractAdd = _masterContractAdd;
        customerPhysicalAdd = _customerPhysicalAdd;
        owner = msg.sender;

    }

    function getCustomerDetails() constant returns(string, string, address[]) {
        return (name, profilePicture, derivativeContracts);

    }

    function getCustomerPhysicalAdd() constant returns(address) {
        return customerPhysicalAdd;
    }

	function addAccountDetails(string _accountHolderName, uint _accountNo, string _accountBankName, string _ifscCode) returns(address) {
        address lastCreated = new Account(_accountHolderName,_accountNo,_accountBankName,_ifscCode);
        address[] tempCustomerAccounts = customerAccounts;
        tempCustomerAccounts.push(lastCreated);
        return lastCreated;
    }

	function getAccounts() constant constant returns(address[]) {
        return (customerAccounts);
    }

    function killCustomers() {
        if (msg.sender == owner) {
            address[] _derivativeContracts = derivativeContracts;
            for (uint i = 0; i < _derivativeContracts.length; ++i) {
                DerivativeContract(_derivativeContracts[i]).killDerivativeContracts();
            }

			address[] _customerAccounts = customerAccounts;
            for (uint j = 0; j < _customerAccounts.length; ++j) {
                Account(_customerAccounts[j]).killAccount();
            }

            suicide(owner);
        }
    }

	function() {
	     throw;
	}
}

contract MasterContract {

    address[] admins;
    address[] banks;
    address[] customers;
    address[] assets;
    address lastCreatedBank;
    address owner;
    address masterContractAdd;
    uint eventId;

    event AddMsg(address indexed _sender, string _eventType, uint _time, string _derivativeContractStatus, uint _premium, address _derivativeContractAddress, uint eventId, string docHash,string _reason, uint _qty);

    mapping(address => address) traderMapping;

    mapping(address => address) customerMapping;

    function addAdmin(address adminAddress) {
        address[] tempAdmins = admins;
        tempAdmins.push(adminAddress);

    }

    function getAdmins() constant returns(address[]) {
        return admins;
    }

    function addBank(string name) returns(address bankAddress) {
        lastCreatedBank = new Bank(name, this);
        address[] tempBanks = banks;
        tempBanks.push(lastCreatedBank);
        return lastCreatedBank;
    }

    function getBanks() constant returns(address[]) {
        return banks;
    }

    function addCustomer(address customerPhysicalAdd, string name) returns(address) {
        address lastCreatedCustomer = new Customer(name, this, customerPhysicalAdd);
        address[] tempCustomers = customers;
        tempCustomers.push(lastCreatedCustomer);
        customerMapping[customerPhysicalAdd] = lastCreatedCustomer;
        return lastCreatedCustomer;

    }

    function getAllCustomers() returns(address[]) {
        return customers;
    }

    function getCustomerByPhysicalAdd(address physicalAdd) constant returns(address) {
        return customerMapping[physicalAdd];
    }

    function AddAsset(string assetName) returns(address) {
        address lastCreatedAsset = new Asset(assetName, this);
        address[] tempAssets = assets;
        tempAssets.push(lastCreatedAsset);
    }

    function getAssets() constant returns(address[]) {
        return assets;
    }

    function addTraders(address bank, address traderPhysicalAddress, string traderName) returns(address) {
        address lastCreatedTrader = new Trader(bank, traderName, masterContractAdd, traderPhysicalAddress);
        traderMapping[traderPhysicalAddress] = lastCreatedTrader;
        Bank(bank).addTrader(lastCreatedTrader);
        return lastCreatedTrader;
    }

    function getTraderByPhysicalAdd(address physicalAdd) constant returns(address) {
        return traderMapping[physicalAdd];
    }

    function create() {
        owner = msg.sender;
        masterContractAdd = this;
    }

    function MasterContract() {
        owner = msg.sender;

    }

    function eventTrigger(address _sender, string _eventType, uint _time, string _derivativeContractStatus, uint _premium, address _derivativeContractAddress, string docHash ,string _reason,uint _qty) {
        ++eventId;
        AddMsg(_sender, _eventType, _time, _derivativeContractStatus, _premium, _derivativeContractAddress, eventId, docHash,_reason,_qty);

    }

    function remove() returns(bool) {
        if (msg.sender == owner) {
            address[] _banks = banks;
            for (uint i = 0; i < _banks.length; ++i) {
                Bank(_banks[i]).killBanks();
            }
            address[] _assets = assets;
            for (uint j = 0; j < _assets.length; ++j) {
                Asset(_assets[j]).killAssets();
            }

            address[] _customers = customers;
            for (uint k = 0; k < _customers.length; ++k) {
                Customer(_customers[k]).killCustomers();
            }

            suicide(owner);

            return true;
        } else
            return false;
    }

	function() {
	     throw;
	}
}
