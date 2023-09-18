// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.8.0;
import "@openzeppelin/contracts/utils/Strings.sol";

contract latestcf{

address owner;

address[] intermediaries;
   
constructor() public {
      owner = msg.sender;
      intermediaries.push(msg.sender);
   }

mapping(address=>bool) internal add_bool_map;

uint256 sku;

struct product{
    uint256 id;
    string name;
    string description;
    uint mrp;
    uint256 doc;
    string ownerName;
    string cid;
    string[] records;

}
string[] tempStringArray;

mapping(uint256=>product) public sku_pr_map;

product private useProduct;

modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

modifier onlyPermitted {

      require(add_bool_map[msg.sender]);
      _;
   }

function addIntermediary (address _address) public onlyOwner{
    intermediaries.push(_address);
    add_bool_map[_address] = true;
}

function createProduct(string memory _ownerName, string memory _cid, uint _id, uint256 _sku, string memory _description, uint _mrp, string memory _name)public  onlyOwner{
    useProduct = product(_id, _name, _description, _mrp, block.timestamp, _ownerName, _cid, tempStringArray);
    useProduct.records.push(_ownerName);
    useProduct.records.push(Strings.toString(block.timestamp));
    useProduct.records.push(_cid);
    sku_pr_map[_sku] = useProduct;
}

function updateProduct(string memory _ownerName, string memory _cid, uint256 _sku) public onlyPermitted{
    sku_pr_map[_sku].ownerName = _ownerName;
    sku_pr_map[_sku].cid = _cid;
    sku_pr_map[_sku].records.push(_ownerName);
    sku_pr_map[_sku].records.push(Strings.toString(block.timestamp));
    sku_pr_map[_sku].records.push(_cid);
}

function getRecords(uint256 _sku)public view returns (string[] memory){
    return sku_pr_map[_sku].records;
}

}