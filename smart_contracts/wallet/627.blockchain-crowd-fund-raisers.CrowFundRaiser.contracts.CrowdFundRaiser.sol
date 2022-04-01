// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract CrowdFunding{

    struct Fundraiser{
        uint id;
        string time;
        uint totalMoney;
        uint collectedMoney;
        string[] image;
        string title;
        bool urgent;
        address payee;
        string fileUrl;
    }

    Fundraiser[] public arr;
    uint public tokenId;
    string public CrowdFundRaiserName;
    string public logoUrlId;
    address public nullAddress = address(0);

    constructor(string memory _name){
        bytes memory paramString = bytes(_name);
        require(paramString.length != 0, "Invalid contract crowd fund raiser name");
        CrowdFundRaiserName = _name;
    }

    function addLogoUrlId(string memory _logoUrlId) public {
        bytes memory paramString = bytes(_logoUrlId);
        require(paramString.length != 0, "Invalid logo url id");
        logoUrlId = _logoUrlId;
    }

    function addFundraiser(string memory _time, uint _totalMoney, uint _collectedMoney, string[] memory _image, string memory _title, bool _urgent
    , address _payee, string memory _fileUrl) public {
        require(_payee != address(0), "Invalid payee address");
        require(_totalMoney > 0, "Invalid totalMoney");
        require(_image.length >= 4, "there should be atleast 4 image hash is required");
        bytes memory paramString1 = bytes(_title);
        require(paramString1.length != 0, "Invalid title");
        bytes memory paramString2 = bytes(_time);
        require(paramString2.length != 0, "Invalid time");
        bytes memory paramString3 = bytes(_fileUrl);
        require(paramString3.length != 0, "Invalid file url");
        tokenId += 1;
        Fundraiser memory temp = Fundraiser(tokenId, _time, _totalMoney, _collectedMoney, _image, _title, _urgent, _payee, _fileUrl);
        arr.push(temp);
    }

    function getSingleFundRaiser(uint _id) public view returns(Fundraiser memory) {
        require(_id <= arr.length, "Invalid Id");
        return arr[_id-1];
    }


    function updateMoney(uint _money, uint _id) public {
        require(_id <= arr.length, "Invalid Id");
        require(_money > 0, "Invalid amount");
        Fundraiser storage temp = arr[_id-1];
        uint left = temp.totalMoney - temp.collectedMoney;
        require(_money <= left, "amonut should be less than and equal to (totalMoney - collectedMoney)");
        temp.collectedMoney += _money;
    }

    function getAllFundRaiser() public view returns(Fundraiser[] memory) {
        return arr;
    }

    function updateAbout(uint _id, string memory _hash) public {
        require(_id <= arr.length, "Invalid Id");
        bytes memory paramString = bytes(_hash);
        require(paramString.length != 0, "Invalid _file url hash");
        Fundraiser storage temp = arr[_id-1];
        temp.fileUrl = _hash;
    }
}
