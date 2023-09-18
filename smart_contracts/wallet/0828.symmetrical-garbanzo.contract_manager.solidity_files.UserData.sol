// SPXD-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


string constant genderFemale = "F";
string constant genderMale = "M";
bytes32 constant hashF = keccak256(abi.encodePacked(genderFemale));
bytes32 constant hashM = keccak256(abi.encodePacked(genderMale));


contract UserData {
    enum genderType { male, female}
    struct user {
        string name;
        genderType gender;
    }
    user user_obj;

    /// @param gender pass "F" for female, "M" for male
    // It is probably better for gas usage to use a boolean to represent a binary system
    // but comparing strings for equality is interesting to try
    function setUser(string memory name, string memory gender) public {
        genderType gender_type = GenderTypeFromString(gender);
        user_obj = user({name: name, gender: gender_type});
    }

    // get user public function
    // This is similar to getting object from db.
    function getUser() public view returns (string memory, string memory) {
        return (user_obj.name, GenderStringFromGenderType(user_obj.gender));
    }

    function GenderTypeFromString(string memory gender) internal pure returns (genderType) {
        bytes32 inputGenderHash = keccak256(abi.encodePacked(gender));
        if (inputGenderHash == hashF) {
            return genderType.female;
        } else if (inputGenderHash == hashM) {
            return genderType.male;
        }
        revert("gender value should be 'F' for female or 'M' for male");
    }

    function GenderStringFromGenderType(genderType gender) internal pure returns (string memory) {
        if (gender == genderType.male) {
            return genderMale;
        } else {
            return genderFemale;
        }
    }
}