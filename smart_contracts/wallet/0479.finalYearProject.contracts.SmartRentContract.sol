// Learn more about Solidity here: https://solidity.readthedocs.io

// This statement specifies the compatible compiler versions
pragma solidity >=0.5.0;

// Declare a contract called HelloWorld
contract SmartRentContract {
    
    event TenantAssigned(address tenantAddress, uint rentAmount, uint rentDeposit);
    event TenantSigned(address tenantAddress);
    event DepositPaid(address tenantAddress, uint rentDeposit);
    event DepositWithdrawn(address tenantAddress, uint rentDeposit);
    event DepositClaimed(address landlordAddress, uint rentDeposit);
    event RentPaid(address tenantAddress, uint amount);
    event RentWithdrawn(address landlordAddress, uint amount);
    event ApprovedSmartRent(address tenant);

    address payable public landlordAddress;
    string public landlordName;
    string public tenantName;
    
    bool public isSigned = false;
    bool public hasPaidDeposit = false;
    
    mapping (address => bool) public tenantToSigned;
    address payable public tenantAddress;
    uint256 public rentAmount;
    uint256 public rentDeposit;
    uint256 public startDate;
    uint256 public endDate;
    string public roomAddress;

    uint256 public depositInContract = 0;
    uint256 public totalRentLeft;
    uint256 public rentHavePaid = 0;

    constructor(string memory _landlord,
            string memory _tenant,
            address payable _landlordAddress,
            string memory _roomAddress,
            uint256 _startDate,
            uint256 _endDate,
            uint256 _deposit,
            uint256 _rent,
            address payable _tenantAddress)
        public {
            landlordName = _landlord;
            tenantName = _tenant;
            landlordAddress = _landlordAddress;
            roomAddress = _roomAddress;
            startDate = _startDate;
            endDate = _endDate;
            rentDeposit = _deposit;
            rentAmount = _rent;
            totalRentLeft = _rent;
            tenantAddress = _tenantAddress;
    }

    modifier landlordOnly() {
        require(msg.sender == landlordAddress, "Only landlord can call this function");
        _;
    }

    modifier tenantOnly() {
        require(msg.sender == tenantAddress, "Only tenant can call this function");
        _;
    }

    modifier hasSigned() {
        require(isSigned == true, "Tenant must sign the contract before invoking this functionality");
        _;
    }

    modifier notZeroAddres(address addr){
        require(addr != address(0), "0th address is not allowed!");
        _;
    }

    function assignTenant(address _tenantAddress)
      external notZeroAddres(_tenantAddress) {
        require(_tenantAddress != landlordAddress, "Landlord is not allowed to be tenant at the same time");
        emit TenantAssigned(_tenantAddress, rentAmount, rentDeposit);
    }

    function signContract() public {
        require(isSigned == false);
        tenantToSigned[msg.sender] = true;
        isSigned = true;
        emit TenantSigned(msg.sender);
    }

    function payDeposit() external payable tenantOnly {
        require(hasPaidDeposit == false, "Tenant cannot pay deposit more than one time");
        require(isSigned == true, "Tenant need to sign the contract before paying deposit");
        hasPaidDeposit = true;
        depositInContract = depositInContract + msg.value;
        emit DepositPaid(msg.sender, msg.value);
    }

    function withdrawDeposit() external payable tenantOnly {
        require(hasPaidDeposit == true, "Tenant need to pay deposit first");
        require(block.timestamp > endDate, "Tenant can only withdraw deposit after period end");
        require(depositInContract > 0, "Deposit in contract cannot be empty");
        require(totalRentLeft == 0, "Tenant can only withdraw deposit after cleared all rental fee");
        tenantAddress.transfer(depositInContract);
        depositInContract = 0;
        emit DepositWithdrawn(msg.sender, rentDeposit);
    }

    function payRent() external payable tenantOnly {
        require(isSigned == true);
        require(hasPaidDeposit == true, "Tenant need to pay deposit first");
        require(msg.value <= totalRentLeft, "Amount inserted has exceed outstanding rent");
        require(block.timestamp < endDate);
        totalRentLeft = totalRentLeft - msg.value;
        rentHavePaid = msg.value;
        emit RentPaid(msg.sender, msg.value);
    }

    function withdrawRent() external payable landlordOnly {
        require(rentHavePaid != 0, "Tenant has not paid any rent yet");
        landlordAddress.transfer(rentHavePaid);
        emit RentWithdrawn(msg.sender, rentHavePaid);
        rentHavePaid = 0;
    }

    function claimDeposit() external payable landlordOnly {
        require(block.timestamp > endDate, "Landlord can only claim deposit after period end");
        require(totalRentLeft != 0, "Landlord can only claim deposit if tenant did not settle their rent after period end");
        landlordAddress.transfer(depositInContract);
        depositInContract = 0;
        emit DepositClaimed(msg.sender, rentDeposit);
    }

}