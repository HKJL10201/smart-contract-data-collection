pragma solidity ^0.5.12;

contract MyWallet {
    
    uint public max_withdrawl;
    uint public min_withdrawl;
    uint public max_keys = 5;
    uint public contract_balance;
    uint lockingPeriod;
    
    address payable public owner;
    
    bool walletsLocked;
    
    address payable[] public auth_keys;
    
    mapping (address => uint) public times_deposited;
    mapping (address => uint) public times_withdrawn;
    mapping (address => bool) public key_is_authorized;
    
    event AuthKeyAddded(address indexed auth_key);
    event DepositMade(address indexed key, uint indexed amount);
    event WithdrawlMade(address indexed key, uint indexed amount, uint indexed time);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyAuthKey() {
        require(key_is_authorized[msg.sender] = true);
        _;
    }
    
    constructor () public {
        max_withdrawl = 1000 ether;
        min_withdrawl = 1 szabo;
        max_keys = 1;
        owner = msg.sender;
        auth_keys.push(owner) - 1;
        times_withdrawn[msg.sender] = 0;
        key_is_authorized[msg.sender] = true;
    }
    
    function addAuthroizedKey(address payable auth_key) public onlyAuthKey {
        require(max_keys <= 4, "There are 5 keys or less");
        for (uint i = 0; i < auth_keys.length; i++) {
                if(auth_keys[i] == auth_key) {
                revert('Key already stored in array');
            }
        }
        auth_keys.push(auth_key);
        times_withdrawn[auth_key] = 0;
        key_is_authorized[auth_key] = true;
        max_keys = max_keys + 1;
        emit AuthKeyAddded(auth_key);
    }
    
    function removeAuthKey(address bad_key) public onlyAuthKey returns (uint index) {
        for (uint i = 0; i < auth_keys.length; i++) {
            if (auth_keys[i] == bad_key) {
                delete(auth_keys[i]);
                auth_keys.length--;
                key_is_authorized[bad_key] = false;
            }
        }
        max_keys = max_keys - 1;
        return auth_keys.length;
    }

    function deposit() public payable returns (bool success) {
        address(this).balance == address(this).balance + msg.value;
        contract_balance = address(this).balance;
        times_deposited[msg.sender]++;
        emit DepositMade(msg.sender, msg.value);
        return success;
    }
    
    function withdraw(uint amount) public onlyAuthKey returns (bool success) {
        require(max_withdrawl >= amount && amount >= min_withdrawl);
        msg.sender.transfer(amount);
        address(this).balance == address(this).balance - amount;
        contract_balance = contract_balance - amount;
        times_withdrawn[msg.sender]++;
        emit WithdrawlMade(msg.sender, amount, block.timestamp);
        return success;
    }
    
    function timeLock(uint amount_of_time, address k1, address k2, address k3, address k4) public onlyOwner returns (bool success) {
        uint time_block = amount_of_time;
        bool locked;
        require (time_block > 7 days, "The minimum locking period is 7 days, after this time the wallets can be unlocked");
        if (time_block > now) {
            locked == true;
        }
        key_is_authorized[k1] = false;
        key_is_authorized[k2] = false;
        key_is_authorized[k3] = false;
        key_is_authorized[k4] = false;
        locked = true;
        walletsLocked = true;
        lockingPeriod = time_block;
        return success;
    }
    
    function unlockWallets(address k1, address k2, address k3, address k4) public onlyOwner {
        checkLockingPeriod();
        require(now >= lockingPeriod && walletsLocked == true);
        require(key_is_authorized[k1] == false &&
                key_is_authorized[k2] == false && 
                key_is_authorized[k3] == false && 
                key_is_authorized[k4] == false);
        key_is_authorized[k1] = true;
        key_is_authorized[k2] = true;
        key_is_authorized[k3] = true;
        key_is_authorized[k4] = true;
    }
    
    function checkLockingPeriod() public view returns(bool, uint) {
        if (lockingPeriod >= now) {
            return (walletsLocked, lockingPeriod);
        } else {
            revert("The locking period is over");
        }
    }
    
    function () external payable {
        require(msg.data.length == 0);
    }
    
}
