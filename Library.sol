// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract Library is Ownable {
    // - The administrator (owner) of the library should be able to add new books and the number of copies in the library.
    // - Users should be able to see the available books and borrow them by their ID.
    // - Users should be able to return books.
    // - A user should not borrow more than one copy of a book at a time. The users should not be able to borrow a book more times than the copies in the libraries unless copy is returned.
    // - Everyone should be able to see the addresses of all people that have ever borrowed a given book.
    
    struct Book {
        string title;
        uint copies;
    }
    
    Book[] private books;
    mapping(string => bool) isAdded;
    mapping(string => uint) titleToID;
    mapping(uint => address[]) bookHistory;
    mapping(address => mapping(uint => bool)) userBooks;
    
    // Allow contract owner to add a new book to the library or increase its number of copies
    function addBook(Book calldata book) external onlyOwner {
        uint _ID = books.length;
        
        // Add book only if it hasn't already been added, otherwise call add copies function
        if(isAdded[book.title]) {
            _addCopies(titleToID[book.title], book.copies);
        } else {
            books.push(book);
            titleToID[book.title] = _ID;
            isAdded[book.title] = true;
        }
    }
    
    // Add copies function
    function _addCopies(uint _ID, uint _copies) private {
        books[_ID].copies += _copies;
    }
    
    
    
    // Get currently available books list with their respective title and ID
    function getAvailableBooks() external view returns(string[] memory) {
        uint[] memory availableBooksByID = _availableBooksByID();
        string[] memory availableBooks = new string[](availableBooksByID.length);
        
        for(uint i = 0; i < availableBooksByID.length; i++) {
            availableBooks[i] = string(abi.encodePacked("\"", books[availableBooksByID[i]].title, "\"", " - ", _uint2str(availableBooksByID[i])));
        }
        
        return availableBooks;
    }
    
    
    // Pass available books id list
    function _availableBooksByID() private view returns(uint[] memory) {
        uint numAvailableBooks = _checkAvailableBooks();
        uint[] memory availableBooksByID = new uint[](numAvailableBooks);
        
        uint index;
        
        for(uint i = 0; i < books.length; i++) {
            if(books[i].copies > 0) {
                availableBooksByID[index] = i;
                index++;
            }
        }
        
        return availableBooksByID;
    }
    
    // Count number of available books
    function _checkAvailableBooks() private view returns(uint) {
        uint num;
        
        for(uint i = 0; i < books.length; i++) {
            if(books[i].copies > 0) {
                num++;
            }
        }
        
        return num;
    }
    
    // Convert uint to string
    function _uint2str(uint _i) private pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    // Borrow book for user, update remaining copies and add user address to book's history
    function borrowBook(uint _ID) external {
        require(books[_ID].copies > 0, "No available copies of this book");
        require(userBooks[msg.sender][_ID] == false);
        userBooks[msg.sender][_ID] = true;
        books[_ID].copies--;
        
        if(!isAddedToHistory(_ID)) {
            bookHistory[_ID].push(msg.sender);
        }
    }
    
    // Return book from user and update remaining copies
    function returnBook(uint _ID) external {
        require(userBooks[msg.sender][_ID] == true);
        userBooks[msg.sender][_ID] = false;
        books[_ID].copies++;
    }
    
    // Get a list of addresses that have barrowed a specific book
    function getBookHistory(uint _ID) external view returns(address[] memory){
        return bookHistory[_ID];
    }
    
    // Check if user address is unique in the given book's history
    function isAddedToHistory(uint _ID) private view returns(bool) {
        for(uint i = 0; i < bookHistory[_ID].length; i++) {
            if(bookHistory[_ID][i] == msg.sender) {
                return true;
            }
        }
        return false;
    }
}