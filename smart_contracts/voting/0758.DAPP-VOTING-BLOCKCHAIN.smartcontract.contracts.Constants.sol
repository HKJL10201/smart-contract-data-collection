// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Constants {
    string[] public DistrictLevelPosition = [
        "Mayor",
        "Deputy Mayor",
        "Ward Chairperson"
    ];

    string[] public Parties = [
        "NEPALI CONGRESS",
        "EMALAY",
        "MAOIST",
        "NEPAL SOCIALIST PARTY",
        "RASTRIYA PRAJATANTRA PARTY",
        "PEOPLE'S PROGRESSIVE PARTY",
        "LOKTANTRIK SAMAJWADI PARTY NEPAL",
        "INDEPENDENT"
    ];

    string[] public ElectionType = [
        "Federal Parliament",
        "Province wise Election",
        "Local Election"
    ];

    string[] public Provinces = [
        "Eastern Province",
        "Madhesh Pradesh",
        "Bagmati Pradesh",
        "Gandaki Pradesh",
        "Lumbini Pradesh",
        "Karnali Pradesh",
        "Sudur Pashchim Pradesh"
    ];

    mapping(string => uint256) public DistrictLevelPositionDict;
    mapping(string => uint256) public PartiesDict;
    mapping(string => uint256) public ElectionTypeDict;
    mapping(string => uint256) public ProvincesDict;

    constructor(){
        uint256 counter = 1;
        
        // init DistrictLevelPosition dictionery
        for(uint i=0;i<DistrictLevelPosition.length;i++){
            DistrictLevelPositionDict[DistrictLevelPosition[i]] = 1100+counter;
            counter++;
        }

        // reset couter value
        counter = 1;

        // init parties dictionery
        for(uint i=0;i<Parties.length;i++){
            PartiesDict[Parties[i]] = 2200+counter;
            counter++;
        }

        // reset couter value
        counter = 1;

        // init ElectionType dictionery
        for(uint i=0;i<ElectionType.length;i++){
            ElectionTypeDict[ElectionType[i]] = 3300+counter;
            counter++;
        }

        // reset couter value
        counter = 1;

        // init Provinces dictionery
        for(uint i=0;i<Provinces.length;i++){
            ProvincesDict[Provinces[i]] = 4400+counter;
            counter++;
        }
    }
}
