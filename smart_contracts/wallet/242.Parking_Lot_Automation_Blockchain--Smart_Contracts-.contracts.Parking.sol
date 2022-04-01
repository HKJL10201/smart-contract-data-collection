pragma solidity ^0.4.4;

contract Parking {
  mapping (address => uint) public vehicleMap;
  mapping (uint => address) public vehicleMapRev;
  mapping (address => uint) public vehicleCheckIn;
  mapping (address => uint) public vehicleCheckOut;
  mapping (address => uint) public vehicleOffer;
  mapping (address => uint) public vehiclePrice;
  mapping (address => address) public vehiclePayAccount;  
  mapping (address => address) public vehiclePayAccountRev;  
  
  address[] public vehicleAddress;

  uint public difference;
  uint public price;
  uint public numVehicleAdd;
  uint public i;
  uint public inTime;	
  address public adddd;
  uint public finalPrice;
 

  // Constructor
  function Parking() {
        difference = 0;
	numVehicleAdd = 0;
	finalPrice = 0;
	inTime = 0;
	price = 0;
  }

function addVehicle(address Address, uint vehicleNum) {
	vehicleMap[Address] = vehicleNum;
	vehicleMapRev[vehicleNum] = Address;
	numVehicleAdd++;
	vehicleAddress.push(Address);
    }
  
 function checkIn(uint checkInTime, address Address, uint vehicleNum) {
	if( vehicleMap[Address] == vehicleNum) {	
		vehicleCheckIn[Address] = checkInTime;
	}
    }

function payment(address payAddress) public payable returns (bool success) {
	
	
	vehiclePayAccount[adddd] = payAddress;
	vehiclePayAccountRev[payAddress] = adddd;
	return true;
  }
    
function checkOut(uint vehicleNum,uint offer,uint checkOutTime) {
	for(i=0;i<numVehicleAdd;i++)
	{
		adddd = vehicleAddress[i];
		if(vehicleMap[adddd] == vehicleNum){
			inTime = vehicleCheckIn[adddd];
		}
	}
	
	vehicleCheckOut[adddd] = checkOutTime;
	vehicleOffer[adddd] = offer;
	

	difference = checkOutTime - inTime;

	if( difference <= 60) 
		price = 10; 
	else if( difference > 60 && difference <= 180)
		price = 20;
	else if( difference > 180)
		price = 30;

	if(offer == 111) 
		finalPrice = ((price*50)/100);
	else if(offer == 222) 
		finalPrice = ((price*10)/100);
	else
		finalPrice = price;

	vehiclePrice[adddd] = finalPrice;
  }
  
  
  
}//end of conference
