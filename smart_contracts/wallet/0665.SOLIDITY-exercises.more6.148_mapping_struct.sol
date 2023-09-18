//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;


contract Cities {

    struct Cities {
        string name;
        string country;
        uint population;
    }

    mapping(uint => Cities) public citiesMapping;

    Cities[] internal citiesArray;

    function createCities(uint index, string memory _name, string memory _country, uint _population) external {
        Cities memory newCity = Cities(_name, _country, _population);
        citiesMapping[index] = newCity;
        citiesArray.push(newCity);
    }

    function getAllArray() external view returns(Cities[] memory) {
        return citiesArray;
    }

}