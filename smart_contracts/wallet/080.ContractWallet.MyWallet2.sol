pragma solidity ^0.5.12;

contract MyWallet2  {
    
    uint public max_withdrawl;
    uint public min_withdrawl;
    uint public max_keys = 5;
    uint public contract_balance;
    uint lockingPeriod;
    
    address payable public owner;
    
    bool walletsLocked;
    
    address payable[] public auth_keys;

    mapping (address => AuthKey) public authorized_keys;
    
    struct AuthKey {
        address payable key;
        uint deposits;
        uint withdraws;
        bool restricted;
    }
    
    event AuthKeyAddded(address indexed auth_key);
    event DepositMade(address indexed key, uint indexed amount);
    event WithdrawlMade(address indexed key, uint indexed amount, uint indexed time);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyAuthKey() {
        require(authorized_keys[msg.sender].key == msg.sender);
        require(authorized_keys[msg.sender].restricted == false);
        _;
    }
    
    constructor () public payable {
        max_withdrawl = 1000 ether;
        min_withdrawl = 1 szabo;
        max_keys = 1;
        owner = msg.sender;
        authorized_keys[msg.sender] = AuthKey({key: owner, deposits: msg.value, withdraws: 0, restricted: false});
        auth_keys.push(owner);
        emit AuthKeyAddded(owner);
    }
    
    function addAuthroizedKey(address payable auth_key) public onlyAuthKey {
        require(max_keys <= 4, "There are 5 keys or less");
        for (uint i = 0; i < auth_keys.length; i++) {
                if(auth_keys[i] == auth_key) {
                revert('Key already stored in array');
            }
        }
        authorized_keys[auth_key] = AuthKey({key: auth_key, deposits: 0, withdraws: 0, restricted: false});
        max_keys = max_keys + 1;
        emit AuthKeyAddded(auth_key);
    }
    
    function removeAuthKey(address bad_key) public onlyAuthKey returns (uint index) {
        for (uint i = 0; i < auth_keys.length; i++) {
            if (auth_keys[i] == bad_key) {
                delete(auth_keys[i]);
                auth_keys.length--;
                authorized_keys[bad_key].restricted = true;
            }
        }
        max_keys = max_keys - 1;
        return auth_keys.length;
    }

    function deposit() public payable returns (bool success) {
        address(this).balance == address(this).balance + msg.value;
        contract_balance = address(this).balance;
        if (authorized_keys[msg.sender].restricted == false) {
                authorized_keys[msg.sender].deposits++;
        }    
        emit DepositMade(msg.sender, msg.value);
        return success;
    }
    
    function withdraw(uint amount) public onlyAuthKey returns (bool success) {
        require(max_withdrawl >= amount && amount >= min_withdrawl);
        msg.sender.transfer(amount);
        address(this).balance == address(this).balance - amount;
        contract_balance = contract_balance - amount;
        authorized_keys[msg.sender].withdraws++;
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
        authorized_keys[k1].restricted = true;
        authorized_keys[k2].restricted = true;
        authorized_keys[k3].restricted = true;
        authorized_keys[k4].restricted = true;
        locked = true;
        walletsLocked = true;
        lockingPeriod = time_block;
        return success;
    }
    
    function unlockWallets(address k1, address k2, address k3, address k4) public onlyOwner {
        checkLockingPeriod();
        require(now >= lockingPeriod && walletsLocked == true);
        require(authorized_keys[k1].restricted == true &&
                authorized_keys[k2].restricted == true && 
                authorized_keys[k3].restricted == true && 
                authorized_keys[k4].restricted == true);
        authorized_keys[k1].restricted = false;
        authorized_keys[k2].restricted = false;
        authorized_keys[k3].restricted = false;
        authorized_keys[k4].restricted = false;
    }
    
    function checkLockingPeriod() public view returns(bool, uint) {
        if (lockingPeriod >= now) {
            return (walletsLocked, lockingPeriod);
        } else {
            revert("The locking period is over");
        }
    }
    
    function walletInfo(address key) public view returns (uint, uint, bool) {
        return(authorized_keys[key].deposits,
               authorized_keys[key].withdraws,
               authorized_keys[key].restricted);
    }
    
}
