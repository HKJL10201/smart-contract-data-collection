pragma solidity ^0.5.16;

contract CDSC {
  address public _purchaser;
  address public _supplier;
  address public _center;
  string public _resourceName;
  uint public _resourceNumber;
  string public _purchaserName;
  string public _purchaserPurpose;
  string public _commitment;
  uint public _price;
  string public _agreementContent;
  uint256 public _signedDataOfSupplier;
  uint256 public _signedDataOfPurchaser;

  modifier onlySupplier() {
    require (msg.sender == _supplier);
    _;
  }

  modifier onlyPurchaser() {
    require (msg.sender == _purchaser);
    _;
  }

  constructor() public {
    _purchaser = 0x00bFAA40777963f2324e1f5b3e0f427FEa8f4ac7;
    _supplier = 0x00225D5aC189405947e027ddd6c5C6CCf9ED8972;
	_center = 0x62b1e832130672CfeD8CAb10c0919993a505b311;
    _resourceName = "BigData";
    _resourceNumber = 2020215;
    _purchaserName = "SHU";
    _purchaserPurpose = "Research";
    _commitment = "After negotiation, the purchaser and the supplier sign the following data resource purchase agreement based on the principle of equality and mutual benefit.";

  }

  event priceNegotiated(string info, address supplier, uint resourceNumber);
  event priceChecked(string info, address purchaser, uint resourceNumber);
  event agreementAdded(string info, address supplier, uint resourceNumber);
  event agreementChecked(string info, address purchaser, uint resourceNumber);
  event supplierSigned(string info, address supplier, uint resourceNumber);
  event purchaserSigned(string info, address purchaser, uint resourceNumber);

  function negotiationPrice(uint price) onlySupplier public returns (uint) {
    _price = price;
    emit priceNegotiated("The transaction price has been negotiated.", _supplier, _resourceNumber);
    return _price;
  }

  function priceChecking() onlyPurchaser public returns (uint) {
    emit priceChecked("The transaction price has been checked.", _purchaser, _resourceNumber);
    return _price;
  }

  function addAgreement(string memory agreementContent) onlySupplier public returns (string memory) {
    _agreementContent = agreementContent;
    emit agreementAdded("The data resource transaction agreement was added successfully.", _supplier, _resourceNumber);
    return _agreementContent;
  }

  function checkAgreement() onlyPurchaser public returns (string memory) {
    emit agreementChecked("The data resource transaction agreement has been checked.", _purchaser, _resourceNumber);
    return _agreementContent;
  }

  function supplierSignAgreement(uint256 signedBySupplier) onlySupplier public returns (uint256) {
    _signedDataOfSupplier = signedBySupplier;
    emit supplierSigned("The data supplier has signed the agreement.", _supplier, _resourceNumber);
    return _signedDataOfSupplier;
  }

  function purchaserSignAgreement(uint256 signedByPurchaser) onlyPurchaser public returns (uint256) {
    _signedDataOfPurchaser = signedByPurchaser;
    emit purchaserSigned("The data purchaser has signed the agreement.", _purchaser, _resourceNumber);
    return _signedDataOfPurchaser;
  }
}
