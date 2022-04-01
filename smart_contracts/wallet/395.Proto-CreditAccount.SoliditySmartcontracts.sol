pragma solidity ^0.4.11;

/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
*/
contract Ownable {

    address public owner;

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));      
        owner = newOwner;
    }
}

/**
* @title Destructible
* @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
*/
contract Destructible is Ownable {

    function Destructible() payable { } 

    /**
    * @dev Transfers the current balance to the owner and terminates the contract. 
    */
    function destroy() onlyOwner {
        selfdestruct(owner);
    }

    /**
    * @dev Transfers the current balance to the _recipient and terminates the contract.
    * @param _recipient The address to transfercurrent balance.
    */
    function destroyAndSend(address _recipient) onlyOwner {
        selfdestruct(_recipient);
    }
}

/**
* @title UserSmartContract
* @dev Smart contract used manage user account
*/
contract UserSmartContract is Ownable, Destructible {

    address public _userWalletAddress;
    address public _legacySmartContractAddress;
    address public _heirWalletAddress;
    uint public _intervalPoL;
    uint public _nextPoLTimestampExpire;

    // Constructor. Define interval (in secondes) for PoL checks (manually checks)
    function UserSmartContract(uint intervalPoL) {
        _intervalPoL = intervalPoL;
        _nextPoLTimestampExpire = now + _intervalPoL;
    }

    /**
    * @dev Methode used by the user to credit his account
    * Send 5% to the user wallet
    * Send 90% to the Legacy smart contract
    * This smart contract keept 5%
    */
    function creditAccount() public payable {
        if(msg.value > 0)
        {
            _userWalletAddress.transfer(msg.value*5/100);
            LegacySmartContract legacySmartContract = LegacySmartContract(_legacySmartContractAddress);
            legacySmartContract.distributeTokens.value(msg.value*90/100)();
        }
    } 

    /**
    * @dev PoL (Proof Of Life) methode. Simulate PoL message (plugins, Legacy App...)
    * This methode is used to prove that user is alive
    */
    function checkPoL(bool isAlive){
        if(isAlive){
            _nextPoLTimestampExpire = now + _intervalPoL;
        }
    }

    /**
    * @dev Execute PoL checks. If user is dead, balance of this smart contract is trafered to the heir wallet
    * This methode is used to simulate Oracle automate call
    */
    function processPoL(){
        if(now > _nextPoLTimestampExpire){
            _heirWalletAddress.transfer(this.balance);
        }
    }

    /**
    * @dev Used to set blockchain addresses
    * @param userWalletAddress The address of the user wallet.
    * @param legacySmartContractAddress The address of the lagacy smart contract.
    * @param heirWalletAddress The address of the heir wallet.
    */    
    function setAddress(address userWalletAddress, address legacySmartContractAddress, address heirWalletAddress) onlyOwner {
        _userWalletAddress = userWalletAddress;
        _legacySmartContractAddress = legacySmartContractAddress;
        _heirWalletAddress = heirWalletAddress;
    }

    /** 
    * @dev To withdraw balance of the smart contract if needed
    */
    function withdraw(uint amount) public onlyOwner {
        if (this.balance >= amount) {
            msg.sender.transfer(amount);
        }
    } 
}

/**
* @title LegacySmartContract
* @dev Smart contract used to managed Legacy features
* This version shares tokens to differents addresses
*/
contract LegacySmartContract is Ownable, Destructible {

    address public _holderWalletAddress;
    address public _legacyWalletAddress;
    address public _devWalletAddress;

    /** 
    * @dev Distribute tokens send by user smart contract (when user credits his account)
    * Send 5% to the Legacy wallet
    * Send 5% to the holder wallet
    * Send 85% to the holder wallet
    * This smart contract keept 5%
    */
    function distributeTokens() public payable {
        _legacyWalletAddress.transfer(msg.value*5/100);
        _holderWalletAddress.transfer(msg.value*5/100);
        _devWalletAddress.transfer(msg.value*85/100);
    } 

    /** 
    * @dev To refund smart contract if needed (need of GAZ for exemple)
    */    
    function creditToken() public payable {

    } 

    /**
    * @dev Used to set blockchain addresses
    * @param holderWalletAddress The address of the holder wallet.
    * @param legacyWalletAddress The address of the legacy wallet.
    * @param devWalletAddress The address of the legacy dev team wallet.
    */     
    function setAddress(address holderWalletAddress, address legacyWalletAddress, address devWalletAddress) onlyOwner {
        _holderWalletAddress = holderWalletAddress;
        _legacyWalletAddress = legacyWalletAddress;
        _devWalletAddress = devWalletAddress;
    }

    /** 
    * @dev To withdraw balance of the smart contract if needed
    */
    function withdraw(uint amount) public onlyOwner {
        if (this.balance >= amount) {
            msg.sender.transfer(amount);
        }
    } 
}