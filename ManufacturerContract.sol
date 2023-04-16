// SPDX-License-Identifier: GPL-3.0
// To Compile Run: solcjs --optimize --bin ManufacturerContract.sol -o Smart_Contract_Binary
pragma solidity >=0.8.0 <0.9.0;

// Information on OpenZeppelin Contracts can be found at: https://docs.openzeppelin.com/contracts/4.x/access-control
import "node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "MiddleManContract.sol";
import "UpdateInfo.sol";

contract ManufacturerContract is ERC20, AccessControl {
    MiddleManContract middleManContract;

    // Instatnitate all the different permission levels
    bytes32 private ADMIN =
        0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42;
    bytes32 private ASSIGN_UPDATE =
        0x293ac1473af20b374a0b048d245a81412cd467992bf656b69382c50f310e9f8c;
    bytes32 private IMPLEMENT_UPDATE =
        0x02ab26f719f5550031a1a942ddcb6b91a1c5b98639464444f1bb36c8a35efc27;
    bytes32 private VIEW_PENDING_UPDATES =
        0x4acc1d14ea2d6e85862a81bf8d5c1251286193eed6e3b81aab32a560eecea7ff;
    bytes32[4] private permissionArray = [
        VIEW_PENDING_UPDATES, // VIEW_PENDING_UPDATES
        IMPLEMENT_UPDATE, // IMPLEMENT_UPDATE
        ASSIGN_UPDATE, // ASSIGN_UPDATE
        ADMIN // ADMIN
    ];

    // Error Message if user has incorrect permission
    string private constant _errorMessage = "No Permission";

    mapping(address => UpdateInfo.Update) private myDirectory;
    address[] private pendingUpdates;
    address[] private failedUpdates;

    constructor() ERC20("MyToken", "TKN") {
        _grantRole(ADMIN, msg.sender);
        middleManContract = new MiddleManContract();
    }

    function assignUpdate(
        address _to,
        address _oem,
        string memory _device,
        string memory _version
    ) public {
        require(hasRole(ASSIGN_UPDATE, msg.sender), _errorMessage);
        myDirectory[_to] = middleManContract.getUpdate(_oem, _device, _version);
        pendingUpdates.push(_to);
    }

    // ToDo: This method needs to be looked into
    // May want to look into converting to a JSON and then sending as a string
    function viewPendingUpdates()
        public
        view
        returns (address[] memory _pendingUpdates)
    {
        require(hasRole(VIEW_PENDING_UPDATES, msg.sender), _errorMessage);
        return (pendingUpdates);
    }

    // ToDo: This method needs to be looked into
    // May want to look into converting to a JSON and then sending as a string
    function viewFailedUpdates()
        public
        view
        returns (address[] memory _failedUpdates)
    {
        require(hasRole(VIEW_PENDING_UPDATES, msg.sender), _errorMessage);
        return (failedUpdates);
    }

    function implementUpdate()
        public
        view
        returns (UpdateInfo.Update memory)
    {
        require(hasRole(IMPLEMENT_UPDATE, msg.sender), _errorMessage);
        return (
            myDirectory[msg.sender]
        );
    }

    function successUpdate(address _id) public {
        require(hasRole(IMPLEMENT_UPDATE, msg.sender), _errorMessage);
        delete myDirectory[_id];
    }

    function failUpdate(address _id) public {
        require(hasRole(IMPLEMENT_UPDATE, msg.sender), _errorMessage);
        failedUpdates.push(_id);
    }

    function grantPermission(address _to, uint8 _permission) public {
        require(hasRole(ADMIN, msg.sender), _errorMessage);
        _grantRole(permissionArray[_permission], _to);
    }

    function revokePermission(address _to, uint8 _permission) public {
        require(hasRole(ADMIN, msg.sender), _errorMessage);
        _revokeRole(permissionArray[_permission], _to);
    }

    // This method returns the solidity address of the middleManContract
    function getMiddleManContract()
        public
        view
        returns (MiddleManContract _middleMan)
    {
        require(hasRole(ADMIN, msg.sender), _errorMessage);
        return middleManContract;
    }

    // This method adds the address for the OEM to the middleManContract
    function addOEM(address _oemAddress, string memory _name) public {
        require(hasRole(ADMIN, msg.sender), _errorMessage);
        middleManContract.addOEM(_oemAddress, _name);
    }

    // This method removes the address for the OEM to the middleManContract
    function removeOEM(address _oemAddress) public {
        require(hasRole(ADMIN, msg.sender), _errorMessage);
        middleManContract.removeOEM(_oemAddress);
    }
}
