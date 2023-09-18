pragma solidity ^0.8.0;

// In remix you can import from github
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/GSN/GSNRecipient.sol";
// I think in other deployments you'll need to import this way
// import "@openzeppelin/contracts-ethereum-package/contracts/GSN/GSNRecipient.sol";

interface MCD {
    function approve(address usr, uint wad) external returns (bool);
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address holder) external returns(uint);
}

contract CashPoints is GSNRecipient {
    uint public Count;
    
    struct CashPoint {
        string _name; //short Name
        int _latitude;
        int _longitude;
        uint _phoneNumber;
        uint rate; //local currency to usd rate
        uint endtime; //when time as cashpoint will expire
        bool isCashPoint;
    }
    
    mapping (address=>CashPoint) cashpoints;
    event CreatedCashPoint(address cashpoint, string name, int lat, int long, uint rate, uint endtime);
    
    MCD MCDContract;
    address RevenueAddress;
   
    constructor(address MCDaddress, address _RevenueAddress) public {
        MCDContract = MCD(MCDaddress);
        RevenueAddress = _RevenueAddress;
        
        }
        
    function addCashPoint(string memory name, int mylat, int mylong, uint phone, uint rate, uint duration, uint fee) public {
        // Note: I had to comment out this section to get things working
        // if(block.timestamp >= cashpoints[msg.sender].endtime)
        // {
        //     delete cashpoints[msg.sender];
        //     Count--;
        // }
        require(MCDContract.balanceOf(msg.sender) > fee);
        require(!cashpoints[msg.sender].isCashPoint);
        uint endtime = block.timestamp + duration * 1 days;
        bool isCashPoint = true;
        
        MCDContract.transferFrom(msg.sender, RevenueAddress, fee);
        cashpoints[msg.sender] = CashPoint(name, mylat, mylong, phone, rate, endtime, isCashPoint);
        
        Count++;
        
        emit CreatedCashPoint(msg.sender, name, mylat, mylong, rate, endtime);
    }
    
    //-- The below function support open zeppelin relayed calls --//
    
    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256 maxPossibleCharge
    ) external view override returns (uint256, bytes memory) {
        return _approveRelayedCall();
    }

    // We won't do any pre or post processing, so leave _preRelayedCall and _postRelayedCall empty
    function _preRelayedCall(bytes memory context) internal override returns (bytes32) {
    }

    function _postRelayedCall(bytes memory context, bool, uint256 actualCharge, bytes32) internal override {
    }
}