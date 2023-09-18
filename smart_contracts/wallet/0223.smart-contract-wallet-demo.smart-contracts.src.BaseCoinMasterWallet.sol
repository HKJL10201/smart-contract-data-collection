pragma solidity ^0.8.0;

import "./IWallet.sol";
import "./services/interfaces/IService.sol";

contract BaseCoinMasterWallet is IWallet {

    // The authorised services of the Shield Wallet
    mapping(address => bool) public authorised;

    // The number of services initialized in the Shield Wallet
    uint256 public services;

    // Variable to managing if the wallet is initialised
    bool public initialised; 

    // Owner of the contract
    address public owner;

    // Service executing the next call
    address public staticCallExecutor;

    // Name of your wallet
    string public name;

    bool public locked;

    event ServiceAuthorised(address indexed service);
    event ServiceRevoked(address indexed service);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Invoked(address indexed _service, address indexed target, uint indexed value, bytes data);

    constructor(address[] memory _services, string memory _name) {
        owner = msg.sender;
        services = _services.length;
        initialised = true;
        name = _name;

        for (uint256 i = 0; i < _services.length; i++) {
            authorised[_services[i]] = true;
            emit ServiceAuthorised(_services[i]);
        }
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyService{
        require(authorised[msg.sender], "Not an authorised service");
        _;
    }

    function init(address _owner, address[] calldata _services) external override {
        require(!initialised && services == 0, "Wallet already initialised");
        initialised = true;
        services = _services.length;
        for (uint256 i = 0; i < _services.length; i++) {
            this.addService(_services[i]);
        }
        emit OwnershipTransferred(address(0), _owner);
    }

    function addService(address _service) external override onlyService {
        require(!authorised[_service], "Service already added");
        authorised[_service] = true;
        services++;
        emit ServiceAuthorised(_service);
    }

    function revokeService(address _service) external override onlyService {
        require(authorised[_service], "Service not added");
        require(services > 0, "No services to revoke");
        authorised[_service] = false;
        services--;
        emit ServiceRevoked(_service);
    }

    function callEnabled(bytes4 _signature) public view override returns (address) {
        address callExecutor = staticCallExecutor;
        if (callExecutor != address(0) && IService(callExecutor).supportsStaticCall(_signature)) {
            return callExecutor;
        }
        return address(0);
    }

    function enableStaticCall(address _service, bytes4 /* _method */) external override onlyService {
        if (staticCallExecutor != _service) {
            require(authorised[_service], "Unauthorized executor");
            staticCallExecutor = _service;
        }
        staticCallExecutor = _service;
    }

    function transferOwner(address _newOwner) external override onlyService {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }

    function lock(bool _lock) external onlyService {
        locked = _lock;
    }

    function invoke(address _target, uint _value, bytes calldata _data) external onlyService returns (bytes memory _result) {
        bool success;
        (success, _result) = _target.call{value: _value}(_data);
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        emit Invoked(msg.sender, _target, _value, _data);
    }

    // For receiving ETH
    receive() external payable {
    }

    // Fallback function in case no method matches the call we must delegate
    // to an attached service
    fallback() external payable {
        address service = callEnabled(msg.sig);
        if (service != address(0)) {
            require(authorised[service], "Unauthorized service");

            // solhint-disable-next-line no-inline-assembly
            assembly {
                calldatacopy(0, 0, calldatasize())
                let result := staticcall(gas(), service, 0, calldatasize(), 0, 0)
                returndatacopy(0, 0, returndatasize())
                switch result
                case 0 {revert(0, returndatasize())}
                default {return (0, returndatasize())}
            }
        }
    }
}