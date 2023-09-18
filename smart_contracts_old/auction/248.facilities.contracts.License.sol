pragma solidity ^0.4.18;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./helpers/SafeMath.sol";

contract LicenseContract is Ownable{
    using SafeMath for uint256;
    /*License is like a token*/
    struct License {
        string companyId;
        uint256 issuedTime;
        uint256 expiryTime;
        address[] whitelistedAddresses;
    }
    
    /*
    ** The ID of each asset is an index in this array.
    */
    License[] internal licenses;
    uint256 internal allowedWhitelistedAddresses = 5;
    uint256 private licenseExpiryTime = 365 days;
    mapping (string => uint256) internal companyToLicenseId;
    mapping (string => bool) internal companyExists;
    mapping (address => string[]) public companyMembers;
    /** internal **/
    
    function _isValidLicense(uint256 _licenseId) internal view returns (bool) {
        return licenses[_licenseId].expiryTime > now;
    }
    
    function _isAllowedToAddAddress (uint256 _licenseId) internal view returns (bool) {
        return licenses[_licenseId].whitelistedAddresses.length < allowedWhitelistedAddresses;
    }    

    function _isAllowedToAddBulkAddresses (uint256 _licenseId, uint256 _addressCount) internal view returns (bool) {
        return licenses[_licenseId].whitelistedAddresses.length + _addressCount <= allowedWhitelistedAddresses;
    }
    
    function _renewLicense (uint256 _licenseId) internal returns (bool) {
        licenses[_licenseId].expiryTime = licenses[_licenseId].expiryTime.add(licenseExpiryTime);
        return true;
    }
    
    function _createLicense (string _companyId, address[] _whitelistedAddresses) internal view returns (License) {
        License memory _license = License({
            companyId: _companyId,
            issuedTime: now,
            expiryTime: now.add(licenseExpiryTime),
            whitelistedAddresses: _whitelistedAddresses
        });
        return _license;
    }
    
    function _addCompanyMember(uint256 _licenseId, address _whitelistedAddress) internal returns (bool){
        string storage companyId = licenses[_licenseId].companyId;
        for (uint256 i = 0; i < companyMembers[_whitelistedAddress].length; i++) {
            if (_compareStrings(companyId, companyMembers[_whitelistedAddress][i])) {
                return false;
            }
        }
        
        companyMembers[_whitelistedAddress].push(companyId);
        return true;
    }
    
    function _removeCompanyMember(uint256 _licenseId, address _whitelistedAddress) internal returns (bool){
        string storage companyId = licenses[_licenseId].companyId;
        uint256 lastIndex = companyMembers[_whitelistedAddress].length - 1;
        for (uint256 i = 0; i < companyMembers[_whitelistedAddress].length; i++) {
            if (_compareStrings(companyId, companyMembers[_whitelistedAddress][i])) {
                companyMembers[_whitelistedAddress][i] = companyMembers[_whitelistedAddress][lastIndex];
                delete companyMembers[_whitelistedAddress][lastIndex];
                companyMembers[_whitelistedAddress].length = companyMembers[_whitelistedAddress].length - 1;
                return true;
            }
        }
        
        return false;
    }

    function _compareStrings (string first, string second) internal returns (bool) {
        return keccak256(first) == keccak256(second);
    }
    
     /** anyone can call these functions**/
    function isValidLicense(uint256 _licenseId) public view returns (bool) {
        return _isValidLicense(_licenseId);
    }
    
    function getLicenseIdByCompanyId(string _companyId) public view returns (uint256) {
        require(companyExists[_companyId]);
        return companyToLicenseId[_companyId];    
    }

    function getLicenseCompanyId(uint256 _licenseId) public view returns (string) {
        return licenses[_licenseId].companyId;
    }
    
    function getLicenseIssuedTime(uint256 _licenseId) public view returns (uint256) {
        return licenses[_licenseId].issuedTime;
    }

    function getLicenseExpiryTime(uint256 _licenseId) public view returns (uint256) {
        return licenses[_licenseId].expiryTime;
    }

    function getLicenseWhitelistedAddresses(uint256 _licenseId) public view returns (address[]) {
        return licenses[_licenseId].whitelistedAddresses;
    }
    
    function setAllowedWhitelistedAddresses (uint256 _allowedAddresses) onlyOwner public returns (uint256){
        require(_allowedAddresses >= 1);
        allowedWhitelistedAddresses = _allowedAddresses;
        return allowedWhitelistedAddresses;
    }
    
    function getAllowedWhitelistedAddresses () public view returns (uint256){
        return allowedWhitelistedAddresses;
    }
    
    function setLicenseExpiryTime (uint256 _licenseExpiryTime) onlyOwner public returns (uint256){
        licenseExpiryTime = _licenseExpiryTime;
        return licenseExpiryTime;
    }
    
    function revokeLicense(uint256 _licenseId) onlyOwner public returns (bool) {
        require(_isValidLicense(_licenseId));
        // Set expiry date to yesterday, rendering license expired
        licenses[_licenseId].expiryTime = now - 1 days;
        return true;
    }
    
    function getLicenseExpiryTime () public view returns (uint256){
        return licenseExpiryTime;
    }
    
    function getLicenseInfo(uint256 _licenseId) public view returns(string companyId, uint256 issuedTime, uint256 expiryTime, address[] whitelistedAddresses) {
        return (
            getLicenseCompanyId(_licenseId),
            getLicenseIssuedTime(_licenseId),
            getLicenseExpiryTime(_licenseId),
            getLicenseWhitelistedAddresses(_licenseId)
        );
    }
    
    function getCompanyIdByAddress (address _whitelistedAddress) public view returns (string[]) {
        return companyMembers[_whitelistedAddress];
    }
     
    /* Events */
    
    event LicenseIssued (
        address indexed owner,
        uint256 licenseId,
        string companyId,
        uint256 issuedTime,
        uint256 expiryTime
    );
}