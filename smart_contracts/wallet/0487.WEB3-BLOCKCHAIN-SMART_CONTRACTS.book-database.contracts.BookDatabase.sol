/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract BookDatabase {
    struct Book {
        string title;
        uint16 year;
    }

    uint32 private nextId = 0;
    address private immutable owner;
    mapping(uint32 => Book) public books;
    uint32 public count = 0;

    constructor() {
        owner = msg.sender;
    }

    modifier restricted() {
        require(owner == msg.sender, "You don't have permissions to do this.");
        _;
    }

    function compare(string memory str1, string memory str2) private pure returns(bool) {
        bytes memory arrA = bytes(str1);
        bytes memory arrB = bytes(str2);
        return arrA.length == arrB.length && keccak256(arrA) == keccak256(arrB);
    }

    function bookExists(uint32 id) private view returns(bool) {
        return bytes(books[id].title).length > 0;
    }

    function addBook(Book memory newBook) public {
        nextId++;
        books[nextId] = newBook;
        count++;
    }

    function editBook(uint32 id, Book memory updatedBookInfos) public {
        require(bookExists(id), "Book not found.");
        Book memory oldBook = books[id];

        if (!compare(oldBook.title, updatedBookInfos.title) && !compare(updatedBookInfos.title, "")) {
            books[id].title = updatedBookInfos.title;
        }

        if (oldBook.year != updatedBookInfos.year && updatedBookInfos.year > 0) {
            books[id].year = updatedBookInfos.year;
        }
    }

    function removeBook(uint32 id) public restricted {
        require(bookExists(id), "Book not found.");
        delete books[id];
        count--;
    }
}