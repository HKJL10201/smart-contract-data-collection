pragma solidity ^0.4.24;
import "./J8TTokenInterface.sol";
import "./FeeInterface.sol";
import "./Pausable.sol";
import "./SafeMath.sol";

contract WalletCoordinator is Pausable {

  using SafeMath for uint256;

  J8TTokenInterface public tokenContract;
  FeeInterface public feeContract;
  address public custodian;

  event TransferSuccess(
    address indexed fromAddress,
    address indexed toAddress,
    uint amount,
    uint networkFee
  );

  event TokenAddressUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  event FeeContractAddressUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  event CustodianAddressUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Allows the current smart contract to transfer amount of tokens from fromAddress to toAddress
   */
  function transfer(address _fromAddress, address _toAddress, uint _amount, uint _baseFee) public onlyAdmin whenNotPaused {
    require(_amount > 0, "Amount must be greater than zero");
    require(_fromAddress != _toAddress,  "Addresses _fromAddress and _toAddress are equal");
    require(_fromAddress != address(0), "Address _fromAddress is 0x0");
    require(_fromAddress != address(this), "Address _fromAddress is smart contract address");
    require(_toAddress != address(0), "Address _toAddress is 0x0");
    require(_toAddress != address(this), "Address _toAddress is smart contract address");
  
    uint networkFee = feeContract.getFee(_baseFee, _amount);
    uint fromBalance = tokenContract.balanceOf(_fromAddress);

    require(_amount <= fromBalance, "Insufficient account balance");

    require(tokenContract.transferFrom(_fromAddress, _toAddress, _amount.sub(networkFee)), "transferFrom did not succeed");
    require(tokenContract.transferFrom(_fromAddress, custodian, networkFee), "transferFrom fee did not succeed");

    emit TransferSuccess(_fromAddress, _toAddress, _amount, networkFee);
  }

  function getFee(uint _base, uint _amount) public view returns (uint256) {
    return feeContract.getFee(_base, _amount);
  }

  function setTokenInterfaceAddress(address _newAddress) external onlyOwner whenPaused returns (bool) {
    require(_newAddress != address(this), "The new token address is equal to the smart contract address");
    require(_newAddress != address(0), "The new token address is equal to 0x0");
    require(_newAddress != address(tokenContract), "The new token address is equal to the old token address");

    address _oldAddress = tokenContract;
    tokenContract = J8TTokenInterface(_newAddress);
    
    emit TokenAddressUpdated(_oldAddress, _newAddress);

    return true;
  }

  function setFeeContractAddress(address _newAddress) external onlyOwner whenPaused returns (bool) {
    require(_newAddress != address(this), "The new fee contract address is equal to the smart contract address");
    require(_newAddress != address(0), "The new fee contract address is equal to 0x0");

    address _oldAddress = feeContract;
    feeContract = FeeInterface(_newAddress);
    
    emit FeeContractAddressUpdated(_oldAddress, _newAddress);

    return true;
  }

  function setCustodianAddress(address _newAddress) external onlyOwner returns (bool) {
    require(_newAddress != address(this), "The new custodian address is equal to the smart contract address");
    require(_newAddress != address(0), "The new custodian address is equal to 0x0");

    address _oldAddress = custodian;
    custodian = _newAddress;
    
    emit CustodianAddressUpdated(_oldAddress, _newAddress);

    return true;
  }
}