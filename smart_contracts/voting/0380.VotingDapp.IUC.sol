pragma solidity 0.8.0;

contract IUC{

        struct Details {
            string name;
            uint age;
            string gender;
            address userAddress;
        }

        Details private _myData;
        mapping(address => uint256) internal _auth;

        constructor(string memory name, uint age, string memory gender, address userAddress, address eciMember) {
            _myData.name = name;
            _myData.age = age;
            _myData.gender = gender;
            _myData.userAddress = userAddress;
            _auth[eciMember] = block.timestamp + 1000 weeks;
        }


        function GetDetails() external onlyAuth returns(Details memory) {
            return _myData;
        }
        function GiveAccess(address _giveTo, uint256 deadline) external returns(bool) {
            if(msg.sender == _myData.userAddress) {
                _auth[_giveTo] = deadline == 0 ? block.timestamp + 52 weeks : deadline;
            } else {
                return false;
            }
            return true;
        } 


        modifier onlyAuth {
            require(msg.sender == _myData.userAddress || auth[msg.sender] > block.timestamp, "error");
            ;
        }
}