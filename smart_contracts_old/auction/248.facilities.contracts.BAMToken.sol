pragma solidity ^0.4.19;
pragma experimental ABIEncoderV2;

import './ERC721.sol';
import './License.sol';
import "./helpers/SafeMath.sol";
import "./Allowance.sol";
import "./ERC721BasicToken.sol";

contract BAMTokenContract is LicenseContract, ERC721BasicTokenContract {
    using SafeMath for uint256;
    address internal tokenSaleAddress;
    
    modifier onlyOwnerOrTokenSaleContract () {
        require(msg.sender == owner || msg.sender == tokenSaleAddress);
        _;
    }
    
    modifier onlySaleContract () {
        require(msg.sender == tokenSaleAddress);
        _;
    }
    
    constructor(string _name, string _symbol) ERC721BasicTokenContract(_name, _symbol) public {
        
    }
    
    function setTokenSaleAddress (address _tokenSaleAddress) public onlyOwner {
        require(_tokenSaleAddress != address(0));
        tokenSaleAddress = _tokenSaleAddress;
    }
    
    function getTokenSaleAddress () public view returns (address) {
        return tokenSaleAddress;
    }
    
    function hasBAMAccess (address _whitelistedAddress, string _companyId) public view returns (bool) {
        string[] memory companies = getCompanyIdByAddress(_whitelistedAddress);
        for (uint256 i = 0; i < companies.length; i++) {
            if (_compareStrings(companies[i], _companyId)){
                return true;
            }
        }
        return false;
    }

    function mint (address _to, string _companyId, address[] _whitelistedAddresses) external onlyOwnerOrTokenSaleContract returns (uint256 _tokenId){
        require(_to != address(0));
        require(_whitelistedAddresses.length < allowedWhitelistedAddresses);
        require(!companyExists[_companyId]);

        License memory _license = _createLicense(_companyId, _whitelistedAddresses);
        
        _tokenId = licenses.push(_license) - 1;
        _mint(_to, _tokenId);
        
        for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            _addCompanyMember(_tokenId, _whitelistedAddresses[i]);
        }

        companyToLicenseId[_companyId] = _tokenId;
        companyExists[_companyId] = true;
        emit LicenseIssued(_to, _tokenId, _companyId, _license.issuedTime, _license.expiryTime);
        return _tokenId;
    }
    
    function renew (uint256 _licenseId) external onlyOwnerOrTokenSaleContract returns (bool) {
        return _renewLicense(_licenseId);
    }
    
    function findAddress(address[] haystack, address needle) pure internal returns(uint256){
        for (uint256 i = 0; i < haystack.length; i++){
            if (needle == haystack[i]) {
                return i;
            }
        }
        return haystack.length;
    }    
    
    function addLicenseWhitelistedAddress(uint256 _licenseId, address _whitelistedAddress) external onlySaleContract returns (address[]){
        require(_isValidLicense(_licenseId));
        require(_isAllowedToAddAddress(_licenseId));
        require(_whitelistedAddress != address(0));
        License storage license = licenses[_licenseId];
        
        license.whitelistedAddresses.push(_whitelistedAddress);
        _addCompanyMember(_licenseId, _whitelistedAddress);
        return license.whitelistedAddresses;
    }
    
    function addLicenseWhitelistedAddressBulk(uint256 _licenseId, address[] _whitelistedAddresses) external onlySaleContract returns (address[]){
        require(_isValidLicense(_licenseId));
        require(_whitelistedAddresses.length > 0);
        require(_isAllowedToAddAddress(_licenseId));
        require(_isAllowedToAddBulkAddresses(_licenseId, _whitelistedAddresses.length));
        
        License storage license = licenses[_licenseId];
        
        for(uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            if (_whitelistedAddresses[i] != address(0)) {
                license.whitelistedAddresses.push(_whitelistedAddresses[i]);
                _addCompanyMember(_licenseId, _whitelistedAddresses[i]);
            }
        }
        
        return license.whitelistedAddresses;
    }
    
    function removeLicenseWhitelistedAddress(uint256 _licenseId, address _whitelistedAddress) external onlySaleContract returns (address[]){
        require(_isValidLicense(_licenseId));
        require(_whitelistedAddress != address(0));
        License storage license = licenses[_licenseId];
        
        uint lastIndex = license.whitelistedAddresses.length - 1;
        
        uint256 addressIndex = findAddress(license.whitelistedAddresses, _whitelistedAddress);
        if (addressIndex < license.whitelistedAddresses.length){
            license.whitelistedAddresses[addressIndex] = license.whitelistedAddresses[lastIndex];
            delete license.whitelistedAddresses[lastIndex];
            license.whitelistedAddresses.length = license.whitelistedAddresses.length - 1;
            _removeCompanyMember(_licenseId, _whitelistedAddress);
        }
        
        return license.whitelistedAddresses;
    }

    function removeLicenseWhitelistedAddressBulk(uint256 _licenseId, address[] _whitelistedAddresses) external onlySaleContract returns (address[]){
        require(_isValidLicense(_licenseId));
        require(_whitelistedAddresses.length > 0);
        License storage license = licenses[_licenseId];
        
        require(_whitelistedAddresses.length <= license.whitelistedAddresses.length);

        uint lastIndex = license.whitelistedAddresses.length - 1;
        for(uint8 i = 0; i < _whitelistedAddresses.length; i++) {
            uint256 addressIndex = findAddress(license.whitelistedAddresses, _whitelistedAddresses[i]);
            if (addressIndex < license.whitelistedAddresses.length) {
                license.whitelistedAddresses[addressIndex] = license.whitelistedAddresses[lastIndex];
                delete license.whitelistedAddresses[lastIndex];
                license.whitelistedAddresses.length = license.whitelistedAddresses.length - 1;
                lastIndex--;
                _removeCompanyMember(_licenseId, _whitelistedAddresses[i]);
            }
        }
        
        return license.whitelistedAddresses;
    }
    
    function _clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
        require(_isValidLicense(_tokenId));
        super._clearApprovalAndTransfer(_from, _to,_tokenId);
    }
}