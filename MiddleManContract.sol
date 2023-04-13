// SPDX-License-Identifier: GPL-3.0
// To Compile Run: solcjs --optimize --bin ManufacturerContract.sol -o Smart_Contract_Binary
pragma solidity >=0.8.0 <0.9.0;

import "node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MiddleManContract is ERC20, AccessControl {
    bytes32 private ADMIN =
        0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42;
    bytes32 private OEM =
        0x4acc1d14ea2d6e85862a81bf8d5c1251286193eed6e3b81aab32a560eecea7ff;
    bytes32 private MANUFACTURER =
        0x293ac1473af20b374a0b048d245a81412cd467992bf656b69382c50f310e9f8c;

    struct OEMStruct {
        address oemAddress;
        mapping(string => deviceType) deviceTypes;
    }

    struct deviceType {
        mapping(string => update) updates;
    }

    struct update {
        uint256 minerId;
        address CID;
        address userAddress;
        string link;
    }

    // Map used to store updates based on the OEM and deviceType
    mapping(address => OEMStruct) private _OEMIdToAddress;

    string private constant _errorMessage = "No Permission";

    constructor() ERC20("MyToken", "TKN") {
        _setupRole(ADMIN, msg.sender);
    }
    function addUpdate(
        string memory _deviceType,
        string memory _version,
        uint256 _minerId,
        address _CID,
        address _userAddress,
        string memory _link
    ) public {
        require(
            (msg.sender == _OEMIdToAddress[msg.sender].oemAddress) &&
            (hasRole(ADMIN, msg.sender) || hasRole(OEM, msg.sender)),
            _errorMessage
        );
        _OEMIdToAddress[msg.sender].deviceTypes[_deviceType].updates[
            _version
        ] = update(_minerId, _CID, _userAddress, _link);
    }

    function getUpdate(
        address _oemId,
        string memory _deviceType,
        string memory _version
    ) public view returns (update memory) {
        require(
            hasRole(ADMIN, msg.sender) ||
                hasRole(OEM, msg.sender) ||
                hasRole(MANUFACTURER, msg.sender),
            _errorMessage
        );
        return
            _OEMIdToAddress[_oemId].deviceTypes[_deviceType].updates[_version];
    }

    function removeUpdate(
        address _oemId,
        string memory _deviceType,
        string memory _version
    ) public {
        require(
            (msg.sender == _OEMIdToAddress[_oemId].oemAddress) && (hasRole(ADMIN, msg.sender) || hasRole(OEM, msg.sender)),
            _errorMessage
        );
        delete _OEMIdToAddress[_oemId].deviceTypes[_deviceType].updates[
            _version
        ];
    }

    function addOEM(address _oemAddress) public {
        require(hasRole(ADMIN, msg.sender), _errorMessage);
        _grantRole(OEM, _oemAddress);
    }

    function removeOEM(address _oemAddress) public {
        require(hasRole(ADMIN, msg.sender), _errorMessage);
        require(hasRole(OEM, _oemAddress), "OEM not whitelisted");
        _revokeRole(OEM, _oemAddress);
    }
}