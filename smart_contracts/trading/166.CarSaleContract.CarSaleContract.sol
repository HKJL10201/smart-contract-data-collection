pragma solidity >=0.4.22 <0.9.0;

contract CarSaleContract {

    address payable public seller;
    address payable public buyer;
    string public carMakeModel;
    uint public carYear;
    uint public carMileage;
    uint public carPrice;
    bool public carInspectionPassed;
    bool public carSold;
    
    event CarSold(address indexed seller, address indexed buyer, uint indexed carPrice);
    
    constructor(address payable _seller, string memory _carMakeModel, uint _carYear, uint _carMileage, uint _carPrice) {
        seller = _seller;
        carMakeModel = _carMakeModel;
        carYear = _carYear;
        carMileage = _carMileage;
        carPrice = _carPrice;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only the seller can perform this action.");
        _;
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only the buyer can perform this action.");
        _;
    }
    
    function buyCar() public payable {
        require(msg.value == carPrice, "The payment amount does not match the car price.");
        require(carInspectionPassed, "The car inspection did not pass.");
        require(!carSold, "The car has already been sold.");
        buyer = payable(msg.sender);
        seller.transfer(msg.value);
        carSold = true;
        emit CarSold(seller, buyer, carPrice);
    }
    
    function updateCarInspection(bool _carInspectionPassed) public onlySeller {
        carInspectionPassed = _carInspectionPassed;
    }

    function withdrawFunds() public onlySeller {
        require(carSold, "The car has not been sold yet.");
        seller.transfer(address(this).balance);
    }
}
