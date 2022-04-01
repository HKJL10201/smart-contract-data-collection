pragma solidity ^0.5.16;

contract Lottery {
    address[] public addressList;  // original array of address
    uint256[] public indexList;
    
    /*
        Input - newAddress: new address to be added to addressList
    */

    function addAddress(address newAddress) external {
        addressList.push(newAddress);
    }
    
    /*
        You should call this function before calling getRemovedAddressList
        So, you should call setRandomIndex() and then call getRemovedAddressList
        This function contains the algorithm called shuffle.
    */

    function setRandomIndex() external {
        uint length = addressList.length;
        require(length > 0);
        indexList = new uint256[](length);
        for (uint i = 0; i < length; i ++) {
            indexList[i] = i;
        }
        for (uint i = length; i >= 2; i --) {
            uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % (i-1);
            uint temp = indexList[i - 1];
            indexList[i - 1] = indexList[rand];
            indexList[rand] = temp;
        }
    }
    
    /*
        @Input - removeNumber : number to be removed from original array (addressList)
        @Output - newAddressList : new generated array from original array (addressList)
    */

    function getRemovedAddressList(uint removeNumber) external view returns(address[] memory newAddressList) {
        require(addressList.length > removeNumber);
        require(indexList.length == addressList.length);
        newAddressList = new address[](addressList.length - removeNumber);
        for (uint i = 0; i < addressList.length - removeNumber; i ++) {
            newAddressList[i] = addressList[indexList[i]];
        }
        return newAddressList;
    }

    /*
        For unit test
    */

    function getAddressLength() public view returns(uint) {
        return addressList.length;
    }

    function getIndexLength() public view returns(uint) {
        return indexList.length;
    }
}
