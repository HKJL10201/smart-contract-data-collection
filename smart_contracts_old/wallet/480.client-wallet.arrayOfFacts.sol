pragma solidity >=0.4.22 <0.6.0;

contract DiaryContract {
    mapping(address => bool) private approvAddress;
    string[] private diary;

    address creator;
    address private newAddress;


    constructor() public {
        creator = msg.sender;

    }

    function addFacts(string memory newFact) public {
        diary.push(newFact);
    }

    function countFacts() public view returns(uint) {
        return diary.length;
    }

    function getFacts(uint256 index) public view returns(string memory) {
        require(index < diary.length, "Fact index must be within range");
        return diary[index];
    }


    function getCreator() public view returns(address) {
        return creator;
    }

    function getAllFacts() public view returns(string memory) {
        string memory rString;
        for(uint i = 0; i < diary.length; i++) {
            rString = strConcat(rString,diary[i]);
            rString = strConcat(rString,",");
        }
        return rString;
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }

}
