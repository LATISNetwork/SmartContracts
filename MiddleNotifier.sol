// SPDX-License-Identifier: GPL-3.0
// To Compile Run: solcjs --optimize --bin ManufacturerContract.sol -o Smart_Contract_Binary
pragma solidity >=0.8.0 <0.9.0;

contract MiddleManContract {
    struct OEM {
        address smartContract;
        mapping(string => deviceType) deviceTypes;
    }

    struct deviceType {
        string name;
        update[] updateInfo;
    }

    struct update {
        string version;
        fileCoin loc;
    }

    struct fileCoin {
        uint256 minerId;
        address CID;
        address userAddress;
        string link;
    }

    mapping(uint256 => OEM) private OEMIdToAddress;

    string private constant _errorMessage = "No Permission";
}
