// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IERC20Token {
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Shelf {

    uint internal booksLength = 0;
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    struct Book {
        address payable owner;
        string title;
        string cover;
        string summary;
        uint price;
        uint unlocks;
    }
    
    mapping (uint => Book) internal books;

    function addSummary(
        string memory _title,
        string memory _cover,
        string memory _summary,
        uint _price
    ) public {
        uint _unlocks = 0;
        books[booksLength] = Book(
            payable(msg.sender),
            _title,
            _cover,
            _summary,
            _price,
            _unlocks
        );
        booksLength++;
    }
    
    function lockedViewBook(uint _index) public view returns (
        address payable,
        string memory,
        string memory,
        uint,
        uint
    ) {
        return (
            books[_index].owner,
            books[_index].title,
            books[_index].cover,
            books[_index].price,
            books[_index].unlocks
        );
    }
    
    function viewBook(uint _index) public view returns (
        address payable,
        string memory,
        string memory,
        string memory,
        uint,
        uint
    ) {
        return (
            books[_index].owner,
            books[_index].title,
            books[_index].cover,
            books[_index].summary,
            books[_index].price,
            books[_index].unlocks
        );
    }
    
    function editSummary(
        string memory _title,
        string memory _cover,
        string memory _summary,
        uint _price,
        uint _index
    ) public {
        books[_index].title = _title;
        books[_index].cover = _cover;
        books[_index].summary = _summary;
        books[_index].price = _price;
    }

    function buyBook(uint _index) public payable {
        require(
          IERC20Token(cUsdTokenAddress).transferFrom(
            msg.sender,
            books[_index].owner,
            books[_index].price
          ),
          "Transfer failed."
        );
        books[_index].unlocks++;
    }
    
    function getBooksLength() public view returns (uint) {
        return (booksLength);
    }
}