//SPDX-Licence-Identifier: MIT
pragma solidity >=0.8.7;

contract TripHistory {
    
    struct Trip {
        string lat;
        string lon;
    }

    Trip public myTrip = Trip("5","6");

    // Trip[] mean an array of struct variables.
    // string[] mean an array of string variables.
    mapping(string => Trip[]) trips;

    function getTrip(string memory _tripId) public view returns (Trip[] memory) {
        return trips[_tripId];
    }

    function storeTrip(string memory _tripId, string memory _lat, string memory _lon) public  {
        trips[_tripId].push(Trip(_lat, _lon));
    }

}