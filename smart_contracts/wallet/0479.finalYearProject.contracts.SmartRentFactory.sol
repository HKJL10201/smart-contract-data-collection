pragma solidity >=0.5.0;

import './SmartRentContract.sol';

contract SmartRentFactory {

    event NewLease(address contractAddress, address indexed landlord, address indexed tenant);
    
    function createRent(
        string memory _landlord,
        string memory _tenant,
        address payable _landlordAddress,
        string memory _roomAddress,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _deposit,
        uint256 _rent,
        address payable _tenantAddress
    ) public 
    {
        address newContract = address(new SmartRentContract(_landlord,
                                                            _tenant,
                                                            _landlordAddress,
                                                            _roomAddress,
                                                            _startDate,
                                                            _endDate,
                                                            _deposit,
                                                            _rent,
                                                            _tenantAddress));
        emit NewLease(newContract, _landlordAddress, _tenantAddress);
    }
}