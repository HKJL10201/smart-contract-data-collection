// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract certi {
    
  address admin;
  
  constructor() {
    admin = msg.sender;    
  }
  
  modifier onlyAdmin {
      require(msg.sender == admin, "Insuficient privilage");
      _;
  }
  
  struct certificate {
      string courseName;
      string cadndidateName;
      string grade;
      string date;
  }
  
  mapping (string => certificate) public certificateDetails;
  
  function newCertificate (
      string memory _certificateID,
      string memory _courseName,
      string memory _cadndidateName,
      string memory _grade,
      string memory _date ) public onlyAdmin {
          certificateDetails[_certificateID] = certificate(
                                                    _courseName,
                                                    _cadndidateName,
                                                    _grade,
                                                    _date);
      }
}