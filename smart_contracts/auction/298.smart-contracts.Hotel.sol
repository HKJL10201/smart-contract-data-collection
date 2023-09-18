// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract CrypTrip {

    uint private hotelsRegistered;
    uint private travelersRegistered;

    /// Rooms with 2 Person are all full.
    error Rooms2Full();
    /// Rooms with 3 Person are all full.
    error Rooms3Full();
    /// Rooms with 5 Person are all full.
    error Rooms5Full();

    struct Traveler {
        uint hotelsBooked;
        uint level;
    }

    struct Hotel {
        uint Id;
        address payable ownerAddr;
        string name;
        string addr;
        uint pincode;
        string city;
        uint contactNumber;
        uint roomsTwo;
        uint roomsThree;
        uint roomsFive;
        uint roomsTwoPrice;
        uint roomsThreePrice;
        uint roomsFivePrice;
    }

    struct Booking {
        uint hotelId;
        uint checkIn;
        uint checkOut;
        uint roomsTwoCount;
        uint roomsThreeCount;
        uint roomsFiveCount;
        uint totalPrice;
        uint contactNumber;
    }

    struct BookedAlready {
        uint roomsTwoCount;
        uint roomsThreeCount;
        uint roomsFiveCount;
    }

    struct ID {
        uint id;
    }

    mapping(address => ID[]) public myHotels;
    mapping(uint => mapping(uint => BookedAlready)) roomsAvailable;
    mapping(address => Booking) booking;
    mapping(uint => Hotel) public hotel;
    mapping(string => ID[]) public locations;
    mapping(address => Traveler) public traveler;

    function createHotel(
        string memory _hotelName,
        string memory _hotelAddr,
        uint _hotelPincode,
        string memory _hotelCity,
        uint _contactNumber,
        uint _roomsTwo,
        uint _roomsThree,
        uint _roomsFive,
        uint _roomsTwoPrice,
        uint _roomsThreePrice,
        uint _roomsFivePrice
    ) public {
        hotelsRegistered += 1;
        hotel[hotelsRegistered] = Hotel(hotelsRegistered, payable(msg.sender), _hotelName, _hotelAddr, _hotelPincode, _hotelCity, _contactNumber, _roomsTwo, _roomsThree, _roomsFive, _roomsTwoPrice, _roomsThreePrice, _roomsFivePrice);
        myHotels[msg.sender].push(ID(hotel[hotelsRegistered].Id));
        locations[hotel[hotelsRegistered].city].push(ID(hotel[hotelsRegistered].Id));
    }

    function search(string memory _location) public view returns (ID[] memory)  {
        ID[] memory abc = locations[_location];
        return abc;
    }

    function checkAvailability(uint _hotelId, uint _checkIn) public view returns(uint rooms2, uint rooms3, uint rooms5){
       rooms2 = roomsAvailable[_hotelId][_checkIn].roomsTwoCount;
       rooms3 = roomsAvailable[_hotelId][_checkIn].roomsThreeCount;
       rooms5 = roomsAvailable[_hotelId][_checkIn].roomsFiveCount;
       return (rooms2, rooms3, rooms5);
    }

    function updateAvailability(uint _hotelId, uint _checkIn, uint a, uint b, uint c) private {
        roomsAvailable[_hotelId][_checkIn].roomsTwoCount = a;
        roomsAvailable[_hotelId][_checkIn].roomsThreeCount = b;
        roomsAvailable[_hotelId][_checkIn].roomsFiveCount = c;
    }

    function bookHotel (uint _hotelId, uint _checkIn, uint _checkOut, uint _roomsTwoCount, uint _roomsThreeCount, uint _roomsFiveCount, uint _contactNumber) public payable {
        
        require(_checkIn > block.timestamp && _checkOut > _checkIn);
        (uint a, uint b, uint c) = checkAvailability(_hotelId, _checkIn);
        
        if(a == hotel[_hotelId].roomsTwo && _roomsTwoCount > 0)
            revert Rooms2Full();
        
        if(b == hotel[_hotelId].roomsThree && _roomsThreeCount > 0)
            revert Rooms3Full();
        
        if(c == hotel[_hotelId].roomsFive && _roomsFiveCount > 0)
            revert Rooms5Full();

        if(a + _roomsTwoCount > hotel[_hotelId].roomsTwo)
            revert Rooms2Full();
        
        a = a + _roomsTwoCount;

        if(b + _roomsThreeCount > hotel[_hotelId].roomsThree)
            revert Rooms3Full();

        b = b + _roomsThreeCount;
        
        if(c + _roomsFiveCount > hotel[_hotelId].roomsFive)
            revert Rooms5Full();

        c = c + _roomsFiveCount;

        uint roomsTwoPrice = hotel[_hotelId].roomsTwoPrice;
        uint roomsThreePrice = hotel[_hotelId].roomsThreePrice;
        uint roomsFivePrice = hotel[_hotelId].roomsFivePrice;

        uint totalPrice = (_roomsTwoCount * roomsTwoPrice) + (_roomsThreeCount * roomsThreePrice) + (_roomsFiveCount * roomsFivePrice);

        require(msg.value == totalPrice);
        booking[msg.sender] = Booking(_hotelId, _checkIn, _checkOut, _roomsTwoCount, _roomsThreeCount, _roomsFiveCount, totalPrice, _contactNumber);

        updateAvailability(_hotelId, _checkIn, a, b, c);

        hotel[_hotelId].ownerAddr.transfer(msg.value);

        traveler[msg.sender].hotelsBooked++;
        traveler[msg.sender].level++;
    }

}