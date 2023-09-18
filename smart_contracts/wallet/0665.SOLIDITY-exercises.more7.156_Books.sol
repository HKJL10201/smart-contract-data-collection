//SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

contract Library {
    enum BookStatus {AVAILABLE, CHECKEDOUT}

    struct Book {
        string bookName;
        BookStatus status;
    }

    mapping(uint => Book) public BooksMapping;

    function setBook(string memory _name, uint _id, BookStatus _status ) external {
        BooksMapping[_id] = Book(_name, _status);
    }

    function getStatus(uint id) external view returns(BookStatus) {
        return BooksMapping[id].status;
    }
}