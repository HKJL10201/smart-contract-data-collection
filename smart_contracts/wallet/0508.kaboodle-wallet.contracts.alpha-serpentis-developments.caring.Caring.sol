// SPDX-License-Identifier: MIT
// Project Sharing by Alpha Serpentis Developments - https://github.com/Alpha-Serpentis-Developments
// Written by Amethyst C. 

pragma solidity ^0.7.4;

import "../ERC677/ERC677Receiver.sol";
import "../ERC677/ERC677.sol";
import "../Module/Module.sol";
import "../../openzeppelin/math/SafeMath.sol";
import "../../openzeppelin/token/ERC20/IERC20.sol";
import "../../openzeppelin/token/ERC20/SafeERC20.sol";

contract Caring is ERC677Receiver {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct ModuleRequest {
        address module; // Address of the module to add
        address proposer; // Address of the proposer
        uint64 automaticPass; // UNIX time when the module request is automatically passed
        address[] approved; // Addresses of managers who accepted 
    }

    struct TransferRequest {
        address member; // Address of the member requesting
        address payable to; // Address of the receiving party
        address token; // If applicable
        uint256 amount; // Amount of tokens withdrawing
        bytes32 ident; // The identifier of the TransferRequest
        address[] approved; // Current approvals
        address[] rejected; // Current rejected
        bytes data; // Data if any
        bool exists; // Used to know if it exists in the mapping or not
    }

    struct Member {
        address adr; // Address of the member
        bool isManager; // Is a manager of the wallet
        bool allowedToDeposit; // Is allowed to deposit
        bool allowedToWithdraw; // Is allowed to withdraw
    }

    mapping(address => Member) private members;
    mapping(bytes32 => TransferRequest) private pendingOutbound;
    mapping(address => uint256) private userNonce;
    mapping(address => ModuleRequest) private pendingModules;
    mapping(address => bool) private authorizedModules;

    bytes public identifier;
    
    bool private multiSig;
    bool private allowModules;
    bool private publicDeposit;
    uint256 private immutable MAX_ALLOWED_MANAGERS;
    uint256 private totalManagers;
    uint256 private totalMembers;
    uint256 private minimumSig;
    uint256 private moduleAutoAcceptLength;
    uint256 private pendingTransfers;
    
    // Events
    
    event Deposit(address _from, uint256 amount);
    event PendingTransfer(address _from, address _to, address _token, uint256 _amount, uint256 _nonce, bytes32 _transferId);
    event TransferCancelled(address _from, bytes32 _transferId);
    event TransferExecute(address _from, address _to, address _token, bool _success);
    event Withdrawal(address _from, address _to, uint256 _amount);
    event PendingModule(address _module, address _proposer, uint256 _acceptAtUnix);
    event ModuleAdded(address _module);
    event ModuleRemoved(address _module);
    event ModuleAdditionCancelled(address _module, address _proposer);
    
    constructor(
        address _manager, 
        uint256 _maxManagers, 
        bytes memory _contractName, 
        bool _multiSig, 
        uint256 _moduleAutoAcceptLength) 
    {
        require(
            _manager != address(0), 
            "Caring: Must have a manager!"
        );
        require(
            _maxManagers > 0 && 
            _maxManagers < (2**256) - 1, 
            "Caring: Must have at least one manager (this includes yourself)!"
        );
        require(
            bytes(_contractName).length != 0, 
            "Caring: Must have a contract identifier!"
        );
        require(
            _moduleAutoAcceptLength < (2**256) - 1,
            "Caring: Invalid _moduleAutoAcceptLength value passed!"
        );
        
        MAX_ALLOWED_MANAGERS = _maxManagers;
        identifier = _contractName;
        totalManagers = 1;
        totalMembers = 1;
        
        multiSig = _multiSig;
        allowModules = false;
        minimumSig = 1;
        moduleAutoAcceptLength = _moduleAutoAcceptLength;
        
        members[_manager].adr = _manager;
        members[_manager].isManager = true;
        members[_manager].allowedToDeposit = true;
        members[_manager].allowedToWithdraw = true;
    }

    modifier onlyManager {
        verifyOnlyManager();
        _;
    }
    modifier onlyMember {
        verifyOnlyMember();
        _;
    }
    modifier publicDepositCheck {
        verifyPublicDeposit();
        _;
    }
    
    receive() payable external publicDepositCheck { // This does not reject mined Ether or from a selfdestruct
        emit Deposit(msg.sender, msg.value);
    }
    
    // TRANSFER FUNCTIONS
    
    function requestTransfer(
        address payable _to, 
        address _token, 
        uint256 _amount
    ) 
        public 
        onlyMember 
        returns(bytes32) 
    {
        if(_token == address(0)) {
            require(
                address(this).balance >= _amount, 
                "requestTransfer(): Insufficient funds to withdraw!"
            );
        } else {
            IERC20 token;
            token = IERC20(_token);
            require(
                token.balanceOf(_token) >= _amount,
                "requestTransfer(): Insufficient funds to withdraw!"
            );
        }
        
        bytes32 transferId;
        
        transferId = keccak256(
            abi.encode(
                msg.sender, 
                _to, 
                _token, 
                _amount,
                userNonce[msg.sender]++
            )
        );
        TransferRequest memory transferReq;
        
        transferReq.member = msg.sender;
        transferReq.to = _to;
        transferReq.token = _token;
        transferReq.amount = _amount;
        
        if(multiSig) {
            addPendingTx(transferReq);
            emit PendingTransfer(
                msg.sender, 
                _to, 
                _token, 
                _amount, 
                userNonce[msg.sender] - 1, 
                transferId
            );
        } else {
            executeSomeTx(transferReq);
        }
        
        return transferId;
    }
    function approveTransfer(
        bytes32 _index, 
        bool _approve
    ) 
        public 
        onlyMember 
    {
        require(
            multiSig, 
            "approveTransfer(): Can only be used if multi-sig mode is enabled!"
        );
        TransferRequest storage transferReq = pendingOutbound[_index];
        
        // Approve or deny the transaction
        if(_approve) {
            transferReq.approved.push(msg.sender);
        } else {
            transferReq.rejected.push(msg.sender);
        }
        // Check if able to execute or has failed the 51%+ requirement
        verifyMultiSig(transferReq);
    }
    function attemptTransfer(bytes32 _index) public onlyMember {
        verifyMultiSig(pendingOutbound[_index]);
    }
    function manualCancelTransfer(bytes32 _index) public onlyMember {
        require(
            pendingOutbound[_index].member == msg.sender, 
            "manualCancelTransfer(): Must be the member initiating the transfer request to cancel!"
        );
        removePendingTx(_index);
        emit TransferCancelled(
            pendingOutbound[_index].member, 
            _index
        );
    }
    function onTokenTransfer(
        address _from, 
        uint256 _amount, 
        bytes memory _data
    ) 
        public 
        override
        publicDepositCheck 
        returns(bool success) 
    {

    }
    
    // MEMBER MANAGEMENT FUNCTIONS
    
    function addMember(
        address _member, 
        bool _allowDeposit, 
        bool _allowWithdrawal
    ) 
        public 
        onlyManager 
    {
        members[_member].adr = _member;
        members[_member].allowedToDeposit = _allowDeposit;
        members[_member].allowedToWithdraw = _allowWithdrawal;
        
        totalMembers++;
    }
    function removeMember(address _member) public onlyManager {
        delete members[_member];
        
        totalMembers--;
    }
    function addManager(address _newManager) public onlyManager {
        require(
            totalManagers < MAX_ALLOWED_MANAGERS, 
            "addManager(): Maximum managers reached!"
        );
        if(members[_newManager].adr == address(0)) {
            addMember(_newManager, true, true);
        }
        
        members[_newManager].isManager = true;
        totalManagers++;
    }
    function removeManager(address _manager) public onlyManager {
        require(
            msg.sender != _manager, 
            "removeManager(): Cannot remove manager from yourself!"
        );
        
        members[_manager].isManager = false;
        totalManagers--;
    }

    // MODULE FUNCTIONS

    function addModule(address _module) public onlyManager {
        require(
            _module != address(0), 
            "addModule(): Invalid module address!"
        );
        
        ModuleRequest memory moduleReq;
        
        moduleReq.module = _module;
        moduleReq.proposer = msg.sender;
        moduleReq.automaticPass = uint64(
            block.timestamp.add(moduleAutoAcceptLength)
        );

        pendingModules[_module] = moduleReq;
        emit PendingModule(
            _module, 
            msg.sender, 
            moduleReq.automaticPass
        );
    }
    function removeModule(address _module) public onlyManager {
        require(
            _module != address(0),
            "removeModule(): Invalid module address!"
        );
        require(
            authorizedModules[_module],
            "removeModule(): Module is not authorized (therefore it cannot be removed)!"
        );
        delete authorizedModules[_module];
    }
    function expediteModuleAddition(address _module) public onlyManager {
        require(
            _module != address(0),
            "expediteModuleAddition(): Invalid module address!"
        );
        require(
            pendingModules[_module].approved.length == totalManagers,
            "expediteModuleAddition(): Cannot be expedited; not enough approvals"
        );
        authorizeModule(_module);
    }
    function approvePendingModule(address _module) public onlyManager {
        require(
            _module != address(0),
            "approvePendingModule(): Invalid module address!"
        );
        require(
            pendingModules[_module].module != address(0),
            "approvePendingModule(): Module is not pending/DNE"
        );
        pendingModules[_module].approved.push(msg.sender);
    }
    function cancelPendingModule(address _module) public onlyManager {
        require(
            _module != address(0),
            "cancelPendingModule(): Invalid module address!"
        );
        // Check if you can still cancel the pending module
        ModuleRequest memory pending = pendingModules[_module];

        if(pending.automaticPass >= block.timestamp) { // Will pass, even if you wanted to cancel
            authorizeModule(_module);
        } else {
            delete pendingModules[_module];
        }
    }
    function interactWithModule(address _module, bytes memory _data) external onlyMember returns(bool success, bytes memory returnData) {
        require(
            _module != address(0),
            "Module cannot be 0 address!"
        );
        require(
            authorizedModules[_module],
            "interactWithModule(): Not authorized"
        );
        Module interactWith = Module(_module);
        interactWith.execute(_data);
    }
    
    // SIMPLE SETTER FUNCTIONS
    
    function setMemberAllowedToDeposit(
        address _member, 
        bool _allowed
    ) 
        public 
        onlyManager 
    {
        members[_member].allowedToDeposit = _allowed;
    }
    function setMemberAllowedToWithdraw(
        address _member, 
        bool _allowed
    ) 
        public 
        onlyManager 
    {
        members[_member].allowedToWithdraw = _allowed;
    }
    function setMultiSig(
        bool _enable
    ) 
        public 
        onlyManager 
    {
        multiSig = _enable;
    }
    function setMinimumMultiSig(
        uint256 _amount, 
        bool _useSuggested
    ) 
        public 
        onlyManager 
    {
        require(
            _amount <= totalMembers && 
            _amount > 0, 
            "setMinimumMultiSig(): Invalid minimum multi-signature"
        );

        if(_useSuggested)
            minimumSig = suggestedSigners(totalMembers);
        else
            minimumSig = _amount; // This does NOT check if it passes a 50%...
    }

    // MISC FUNCTIONS

    function suggestedSigners(
        uint256 _count
    ) 
        public 
        pure 
        returns(uint256) 
    {
        require(
            _count > 0 
            && _count < (2**256) - 1, 
            "suggestedSigners(): Invalid '_count' value!"
        );

        //recommended = _count/2 + _count%2;
        uint256 recommended = _count.div(2).add(_count.mod(2));

        return recommended;
    }
    
    function getIdentifier() public view returns(bytes memory) {
        return identifier;
    }
    function getTotalMembers() public view returns(uint256) {
        return totalMembers;
    }
    function isMultiSig() public view returns(bool) {
        return multiSig;
    }
    function getMinimumSig() public view returns(uint256) {
        return minimumSig;
    }
    function getPendingTransferCount() public view returns(uint256) {
        return pendingTransfers;
    }
    function isMember(address _address) public view returns(bool) {
        return members[_address].adr != address(0);
    }
    function isMemberAllowedToDeposit(address _address) public view returns(bool) {
        return members[_address].allowedToDeposit;
    }
    function isMemberAllowedToWithdraw(address _address) public view returns(bool) {
        return members[_address].allowedToWithdraw;
    }
    function isManager(address _address) public view returns(bool) {
        return members[_address].isManager;
    }

    // INTERNAL FUNCTIONS
    function verifyPublicDeposit() internal view {
        if(publicDeposit) {
            verifyOnlyMember();
        }
    }
    function verifyOnlyMember() internal view {
        require(
            members[msg.sender].adr != address(0),
            "onlyMember: Must be a member!"
        );
    }
    function verifyOnlyManager() internal view {
        require(
            members[msg.sender].isManager, 
            "onlyManager: Must be the manager!"
        );
    }
    function verifyMultiSig(TransferRequest memory _tx) internal {
        if(_tx.approved.length >= minimumSig) {// If passes definitely, execute transfer
            executeSomeTx(_tx);
        } else if(totalMembers.sub(_tx.rejected.length) < minimumSig) { // If fails definitely, cancel the transfer
            removePendingTx(_tx.ident);

            emit TransferCancelled(
                pendingOutbound[_tx.ident].member, 
                _tx.ident
            );
        }
    }
    function addPendingTx(TransferRequest memory _tx) internal {
        pendingOutbound[_tx.ident] = _tx;
    }
    function removePendingTx(bytes32 _ident) internal {
        delete pendingOutbound[_ident];
    }
    function executeSomeTx(TransferRequest memory _tx) internal {
        if(_tx.token == address(0))
            executeEtherTx(_tx);
        else
            executeTokenTx(_tx);
    }
    function executeEtherTx(TransferRequest memory _tx) internal {
        if(pendingOutbound[_tx.ident].exists) {
            require(
                pendingOutbound[_tx.ident].amount <= address(this).balance, 
                "executeEtherTx(): Cannot withdraw more than there actually is!"
            );
            pendingOutbound[_tx.ident].to.transfer(pendingOutbound[_tx.ident].amount);

            emit TransferExecute(
                pendingOutbound[_tx.ident].member, 
                pendingOutbound[_tx.ident].to, 
                address(0), 
                true
            );
            removePendingTx(_tx.ident);
        }
    }
    function executeTokenTx(TransferRequest memory _tx) internal {
        ERC677 _token = ERC677(_tx.token);

        try _token.transferAndCall(_tx.to, _tx.amount, _tx.data) {

        } catch {
            // Perform fallback
            IERC20 _fallbackToken = IERC20(_tx.token);

            _fallbackToken.safeTransfer(_tx.to, _tx.amount);
        }

        removePendingTx(_tx.ident);
    }
    function authorizeModule(address _module) internal {
        require(
            _module != address(0),
            "authorizeModule: zero address"
        );
        authorizedModules[_module] = true;
        delete pendingModules[_module];
    }
    
}
