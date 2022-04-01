// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IIntercoin.sol";
import "./interfaces/IIntercoinTrait.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract IntercoinTrait is Initializable, IIntercoinTrait {
    
    address private intercoinAddr;
    bool private isSetup;
    
    /**
     * setup intercoin contract's address. happens once while initialization through factory
     * @param addr address of intercoin contract
     */
    function setIntercoinAddress(address addr) public override returns(bool) {
        require (addr != address(0), 'Address can not be empty');
        require (isSetup == false, 'Already setup');
        intercoinAddr = addr;
        isSetup = true;
        
        return true;
    }
    
    /**
     * got stored intercoin address
     */
    function getIntercoinAddress() public override view returns (address) {
        return intercoinAddr;
    }
    
    /**
     * @param addr address of contract that need to be checked at intercoin contract
     */
    function checkInstance(address addr) internal view returns(bool) {
        
        require (intercoinAddr != address(0), 'Intercoin address need to be setup before');
        return IIntercoin(intercoinAddr).checkInstance(addr);
    }
}