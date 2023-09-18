pragma solidity >=0.5.0;

interface VendorInterface {

    /** External functions */
    function isVendor(address vendor) external returns(bool);
}
