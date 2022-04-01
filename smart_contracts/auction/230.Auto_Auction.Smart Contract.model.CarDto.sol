pragma solidity ^0.5.0;

contract CarDto {
    
    struct Car {
        string vin;
        string year;
        string make;
        string model;
        string state;
        uint miles;
        uint accidents;
        uint initial_value;
    }
    
    Car cars;
    
//    mapping(uint => Car) public carMap;
    
    constructor(string memory _vin, string memory _year, string memory _make, string memory _model, string memory _state, uint _miles, uint _accidents, uint _initial_value) public {
        cars = Car(_vin,_year,_make,_model,_state,_miles,_accidents,_initial_value);
    }
    
    
//   function addBidder(string memory _bidderName, uint _bidAmount) public {
//       bidders = Bidder(_bidderName,_bidAmount);
//   }
/*
    //1. Car VIN
   function getVin() public view returns (string memory) {
      return cars.vin;
   }
   
   function setVin(string memory _vin) public { 
         cars.vin = _vin;
   }
   
   
    //2. Car Year   
   function getCarYear() public view returns (string memory) {
      return cars.year;
   }
   
   function setCarYear(string memory _year) public { 
          cars.year = _year;
   }
   
   
   //3. Car Make   
    function getCarMake() public view returns (string memory) {
      return cars.make;
   }
   
    function setCarMake(string memory _make) public { 
          cars.make = _make;
   }
   
   
   //4. Car Model   
    function getCarModel() public view returns (string memory) {
      return cars.model;
   }
   
    function setCarModel(string memory _model) public { 
          cars.model = _model;
   }
   
   
   //5. Car State   
    function getCarState() public view returns (string memory) {
      return cars.state;
   }
   
    function setCarState(string memory _state) public { 
          cars.state = _state;
   }
   
   
   //6. Car Miles   
   function getCarMiles() public view returns (uint) {
      return cars.miles;
   }
   
   function setCarMiles(uint _miles) public { 
          cars.miles = _miles;
   }
   
   
   
   //7. Car Accidents   
   function getCarAccidents() public view returns (uint) {
      return cars.accidents;
   }
   
   function setCarAccidents(uint _accidents) public { 
          cars.accidents = _accidents;
   }*/
   
   
   
   //8. Car Initial Value   
   function getCarInitialValue() public view returns (uint) {
      return cars.initial_value;
   }
   
   
   function setCarIntialValue(uint _initial_value) public { 
          cars.initial_value = _initial_value;
   }

   
}