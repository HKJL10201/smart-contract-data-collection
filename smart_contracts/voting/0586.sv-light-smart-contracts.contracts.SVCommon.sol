pragma solidity ^0.4.24;


// Some common functions among SCs
// (c) SecureVote 2018
// Author: Max Kaye
// License: MIT
// Note: don't break backwards compatibility


// safe send contract
contract safeSend {
    bool private txMutex3847834;

    // we want to be able to call outside contracts (e.g. the admin proxy contract)
    // but reentrency is bad, so here's a mutex.
    function doSafeSend(address toAddr, uint amount) internal {
        doSafeSendWData(toAddr, "", amount);
    }

    function doSafeSendWData(address toAddr, bytes data, uint amount) internal {
        require(txMutex3847834 == false, "ss-guard");
        txMutex3847834 = true;
        // we need to use address.call.value(v)() because we want
        // to be able to send to other contracts, even with no data,
        // which might use more than 2300 gas in their fallback function.
        require(toAddr.call.value(amount)(data), "ss-failed");
        txMutex3847834 = false;
    }
}


// just provides a payoutAll method that sends to
contract payoutAllC is safeSend {
    address private _payTo;

    event PayoutAll(address payTo, uint value);

    constructor(address initPayTo) public {
        // DEV NOTE: you can overwrite _getPayTo if you want to reuse other storage vars
        assert(initPayTo != address(0));
        _payTo = initPayTo;
    }

    function _getPayTo() internal view returns (address) {
        return _payTo;
    }

    function _setPayTo(address newPayTo) internal {
        _payTo = newPayTo;
    }

    function payoutAll() external {
        address a = _getPayTo();
        uint bal = address(this).balance;
        doSafeSend(a, bal);
        emit PayoutAll(a, bal);
    }
}


// version of payoutAllC that requires getters and setters
contract payoutAllCSettable is payoutAllC {
    constructor (address initPayTo) payoutAllC(initPayTo) public {
    }

    function setPayTo(address) external;
    function getPayTo() external view returns (address) {
        return _getPayTo();
    }
}


// owned contract - added isOwner modifier (otherwise from solidity examples)
contract owned {
    address public owner;

    event OwnerChanged(address newOwner);

    modifier only_owner() {
        require(msg.sender == owner, "only_owner: forbidden");
        _;
    }

    modifier owner_or(address addr) {
        require(msg.sender == addr || msg.sender == owner, "!owner-or");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address newOwner) only_owner() external {
        owner = newOwner;
        emit OwnerChanged(newOwner);
    }
}


// just to give other contracts an ABI - should not be used / deployed
contract controlledIface {
    function controller() external view returns (address);
}


// hasAdmins contract - allows for easy admin stuff
contract hasAdmins is owned {
    mapping (uint => mapping (address => bool)) admins;
    uint public currAdminEpoch = 0;
    bool public adminsDisabledForever = false;
    address[] adminLog;

    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed oldAdmin);
    event AdminEpochInc();
    event AdminDisabledForever();

    modifier only_admin() {
        require(adminsDisabledForever == false, "admins must not be disabled");
        require(isAdmin(msg.sender), "only_admin: forbidden");
        _;
    }

    constructor() public {
        _setAdmin(msg.sender, true);
    }

    function isAdmin(address a) view public returns (bool) {
        return admins[currAdminEpoch][a];
    }

    function getAdminLogN() view external returns (uint) {
        return adminLog.length;
    }

    function getAdminLog(uint n) view external returns (address) {
        return adminLog[n];
    }

    function upgradeMeAdmin(address newAdmin) only_admin() external {
        // note: already checked msg.sender has admin with `only_admin` modifier
        require(msg.sender != owner, "owner cannot upgrade self");
        _setAdmin(msg.sender, false);
        _setAdmin(newAdmin, true);
    }

    function setAdmin(address a, bool _givePerms) only_admin() external {
        require(a != msg.sender && a != owner, "cannot change your own (or owner's) permissions");
        _setAdmin(a, _givePerms);
    }

    function _setAdmin(address a, bool _givePerms) internal {
        admins[currAdminEpoch][a] = _givePerms;
        if (_givePerms) {
            emit AdminAdded(a);
            adminLog.push(a);
        } else {
            emit AdminRemoved(a);
        }
    }

    // safety feature if admins go bad or something
    function incAdminEpoch() only_owner() external {
        currAdminEpoch++;
        admins[currAdminEpoch][msg.sender] = true;
        emit AdminEpochInc();
    }

    // this is internal so contracts can all it, but not exposed anywhere in this
    // contract.
    function disableAdminForever() internal {
        currAdminEpoch++;
        adminsDisabledForever = true;
        emit AdminDisabledForever();
    }
}


// // https://stackoverflow.com/a/40939341
// contract canCheckOtherContracts {
//     function isContract(address addr) constant internal returns (bool) {
//         uint size;
//         assembly { size := extcodesize(addr) }
//         return size > 0;
//     }
// }


// // interface for ENS reverse registrar
// interface ReverseRegistrarIface {
//     function claim(address owner) external returns (bytes32);
// }


// // contract to allow claiming a reverse ENS lookup
// contract claimReverseENS is canCheckOtherContracts {
//     function initReverseENS(address _owner) internal {
//         // 0x9062C0A6Dbd6108336BcBe4593a3D1cE05512069 is ENS ReverseRegistrar on Mainnet
//         address ensRevAddr = 0x9062C0A6Dbd6108336BcBe4593a3D1cE05512069;
//         if (isContract(ensRevAddr)) {
//             ReverseRegistrarIface ens = ReverseRegistrarIface(ensRevAddr);
//             ens.claim(_owner);
//         }
//     }
// }


// is permissioned is designed around upgrading and synergistic SC networks
// the idea is that DBs and datastructs should live in their own contract
// then other contracts should use these - either to edit or read from
contract permissioned is owned, hasAdmins {
    mapping (address => bool) editAllowed;
    bool public adminLockdown = false;

    event PermissionError(address editAddr);
    event PermissionGranted(address editAddr);
    event PermissionRevoked(address editAddr);
    event PermissionsUpgraded(address oldSC, address newSC);
    event SelfUpgrade(address oldSC, address newSC);
    event AdminLockdown();

    modifier only_editors() {
        require(editAllowed[msg.sender], "only_editors: forbidden");
        _;
    }

    modifier no_lockdown() {
        require(adminLockdown == false, "no_lockdown: check failed");
        _;
    }


    constructor() owned() hasAdmins() public {
    }


    function setPermissions(address e, bool _editPerms) no_lockdown() only_admin() external {
        editAllowed[e] = _editPerms;
        if (_editPerms)
            emit PermissionGranted(e);
        else
            emit PermissionRevoked(e);
    }

    function upgradePermissionedSC(address oldSC, address newSC) no_lockdown() only_admin() external {
        editAllowed[oldSC] = false;
        editAllowed[newSC] = true;
        emit PermissionsUpgraded(oldSC, newSC);
    }

    // always allow SCs to upgrade themselves, even after lockdown
    function upgradeMe(address newSC) only_editors() external {
        editAllowed[msg.sender] = false;
        editAllowed[newSC] = true;
        emit SelfUpgrade(msg.sender, newSC);
    }

    function hasPermissions(address a) public view returns (bool) {
        return editAllowed[a];
    }

    function doLockdown() external only_owner() no_lockdown() {
        disableAdminForever();
        adminLockdown = true;
        emit AdminLockdown();
    }
}


contract upgradePtr {
    address ptr = address(0);

    modifier not_upgraded() {
        require(ptr == address(0), "upgrade pointer is non-zero");
        _;
    }

    function getUpgradePointer() view external returns (address) {
        return ptr;
    }

    function doUpgradeInternal(address nextSC) internal {
        ptr = nextSC;
    }
}


// // allows upgrades - all methods that do stuff need the checkUpgrade modifier
// contract upgradable is descriptiveErrors, owned {
//     bool public upgraded = false;
//     address public upgradeAddr;
//     uint public upgradeTimestamp;

//     uint constant ONE_DAY_IN_SEC = 60 * 60 * 24;

//     event ContractUpgraded(uint upgradeTime, address newScAddr);

//     modifier checkUpgrade() {
//         // we want to prevent anyone but the upgrade contract calling methods - this allows
//         // the new contract to get data out of the old contract for those methods
//         // TODO: is there a case where we actually want this? Or are most methods okay to leave as old ones?
//         if (upgraded && msg.sender != upgradeAddr) {
//             doRequire(upgradeAddr.call.value(msg.value)(msg.data), ERR_CALL_UPGRADED_FAILED);
//         } else {
//             _;
//         }
//     }

//     function deprecateAndUpgrade(address _newSC) isOwner() req(upgraded == false, ERR_ALREADY_UPGRADED) public {
//         upgraded = true;
//         upgradeAddr = _newSC;
//         upgradeTimestamp = block.timestamp;
//         emit ContractUpgraded(upgradeTimestamp, upgradeAddr);
//     }

//     function undoUpgrade() isOwner()
//                            req(upgraded == true, ERR_NOT_UPGRADED)
//                            req(block.timestamp < (upgradeTimestamp + ONE_DAY_IN_SEC), ERR_NO_UNDO_FOREVER)
//                            public {
//         // todo
//     }
// }


// For ERC20Interface:
// (c) BokkyPooBah 2017. The MIT Licence.
interface ERC20Interface {
    // Get the total token supply
    function totalSupply() constant external returns (uint256 _totalSupply);

    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) constant external returns (uint256 balance);

    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) external returns (bool success);

    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality
    function approve(address _spender, uint256 _value) external returns (bool success);

    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) constant external returns (uint256 remaining);

    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
