pragma solidity ^0.4.19;

import "./helpers/SafeMath.sol";
import "./BAMToken.sol";
import "./Ownable.sol";

contract ARYToken {
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

contract BAMSaleContract is Ownable{
    BAMTokenContract public assetToken; 
    ARYToken public aryToken;
    address public beneficiaryAddress;
    uint256 internal ARYPerToken = 1 * 10 ** 18;
    
    modifier hasAllowance () {
        // Must have set allowance for sale contract
        require(aryToken.allowance(msg.sender, address(this)) >= ARYPerToken);
        _;
    }
    
    modifier onlyOwnerOf(uint256 _licenseId) {
        require(assetToken.ownerOf(_licenseId) == msg.sender);
        _;
    }
    
    constructor (BAMTokenContract _assetTokenAddress, ARYToken _aryToken, address _beneficiary) public {
        assetToken = _assetTokenAddress;
        aryToken = _aryToken;
        beneficiaryAddress = _beneficiary;
    }
    
    function setBeneficiaryAddress (address _beneficiary) public onlyOwner returns (address){
        require(_beneficiary != address(0));
        beneficiaryAddress = _beneficiary;
        return beneficiaryAddress;
    }
    
    function getBeneficiaryAddress () public view returns (address) {
        return beneficiaryAddress;
    }

    function setARYTokenAddress (ARYToken _aryAddress) public onlyOwner returns (address){
        require(_aryAddress != address(0));
        aryToken = _aryAddress;
        return aryToken;
    }
    
    function getARYAddress () public view returns (ARYToken) {
        return aryToken;
    }

    function setTokenAddress (BAMTokenContract _tokenAddress) public onlyOwner returns (address){
        require(_tokenAddress != address(0));
        assetToken = _tokenAddress;
        return assetToken;
    }
    
    function getTokenAddress () public view returns (BAMTokenContract) {
        return assetToken;
    }
    
    function setARYPerToken (uint256 _aryPerToken) public onlyOwner returns (uint256){
        require(_aryPerToken >= 1);
        ARYPerToken = _aryPerToken;
        return ARYPerToken;
    }
    
    function getARYPerToken () public view returns (uint256) {
        return ARYPerToken;
    }
    
    function makePayment () private returns (bool) {
        return aryToken.transferFrom(msg.sender, beneficiaryAddress, ARYPerToken);
    }
    
    function purchase(string _companyId, address[] _whitelistedAddresses, address _assignee) external hasAllowance returns (uint) {
        require(_assignee != address(0));
        
        // Transfer ARYTokens from sender account to beneficiaryAddress
        require(makePayment());

        uint256 assetId = assetToken.mint(_assignee, _companyId, _whitelistedAddresses);
        return assetId;
    }
    
    function findAddress(address[] haystack, address needle) pure internal returns(uint256){
        for (uint256 i = 0; i < haystack.length; i++){
            if (needle == haystack[i]) {
                return i;
            }
        }
        return haystack.length;
    }    
    
    function addLicenseWhitelistedAddress(uint256 _licenseId, address _whitelistedAddress) public onlyOwnerOf(_licenseId) returns (address[]){
        require(assetToken.isValidLicense(_licenseId));
        require(_whitelistedAddress != address(0));
        
        address[] memory existingAddress = assetToken.getLicenseWhitelistedAddresses(_licenseId);
        uint256 addressIndex = findAddress(existingAddress, _whitelistedAddress);
        
        if (addressIndex < existingAddress.length) {
            return existingAddress;
        }
        
        return assetToken.addLicenseWhitelistedAddress(_licenseId, _whitelistedAddress);
    }
    
    function addLicenseWhitelistedAddressBulk(uint256 _licenseId, address[] _whitelistedAddresses) public onlyOwnerOf(_licenseId) returns (address[]){
        require(assetToken.isValidLicense(_licenseId));
        require(_whitelistedAddresses.length > 0);
        
        address[] memory existingAddresses = assetToken.getLicenseWhitelistedAddresses(_licenseId);
        for(uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            uint256 addressIndex = findAddress(existingAddresses, _whitelistedAddresses[i]);
            if (addressIndex < existingAddresses.length) {
                delete _whitelistedAddresses[addressIndex];
            }
        }
        
        return assetToken.addLicenseWhitelistedAddressBulk(_licenseId, _whitelistedAddresses);
    }
    
    function removeLicenseWhitelistedAddress(uint256 _licenseId, address _whitelistedAddress) public onlyOwnerOf(_licenseId) returns (address[]){
        require(assetToken.isValidLicense(_licenseId));
        require(_whitelistedAddress != address(0));
        
        address[] memory existingAddresses = assetToken.getLicenseWhitelistedAddresses(_licenseId);
        uint256 addressIndex = findAddress(existingAddresses, _whitelistedAddress);
        if (addressIndex >= existingAddresses.length) {
            return existingAddresses;
        }
        
        return assetToken.removeLicenseWhitelistedAddress(_licenseId, _whitelistedAddress);
    }
    
    function removeLicenseWhitelistedAddressBulk(uint256 _licenseId, address[] _whitelistedAddresses) public onlyOwnerOf(_licenseId) returns (address[]){
        require(assetToken.isValidLicense(_licenseId));
        require(_whitelistedAddresses.length > 0);

        return assetToken.removeLicenseWhitelistedAddressBulk(_licenseId, _whitelistedAddresses);
    }

    
    function renew(uint256 _licenseId) external hasAllowance onlyOwnerOf(_licenseId) returns (bool) {
        // Transfer ARYTokens from sender account to beneficiaryAddress
        require(makePayment());

        return assetToken.renew(_licenseId);
    }
}