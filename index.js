console.clear();
require("dotenv").config();
const {
  AccountId,
  PrivateKey,
  Client,
  FileCreateTransaction,
  ContractCreateTransaction,
  ContractFunctionParameters,
  ContractExecuteTransaction,
  ContractCallQuery,
  Hbar,
  ContractCreateFlow,
  PublicKey
} = require("@hashgraph/sdk");
const { getRandomValues } = require("crypto");
const fs = require("fs");

// Read in .env files
const accountId1 = process.env.MY_ACCOUNT_ID1;
const publicKey1 = process.env.MY_PUBLIC_KEY1;
const privateKey1 = process.env.MY_PRIVATE_KEY1;

const accountId2 = process.env.MY_ACCOUNT_ID2;
const publicKey2 = process.env.MY_PUBLIC_KEY2;
const privateKey2 = process.env.MY_PRIVATE_KEY2;

const accountId3 = process.env.MY_ACCOUNT_ID3;
const publicKey3 = process.env.MY_PUBLIC_KEY3;
const privateKey3 = process.env.MY_PRIVATE_KEY3;

// Configure accounts and client
const operatorId1 = AccountId.fromString(accountId1);
const operatorKey1 = PrivateKey.fromString(privateKey1);

const operatorId2 = AccountId.fromString(accountId2);
const operatorKey2 = PrivateKey.fromString(privateKey2);

const operatorId3 = AccountId.fromString(accountId3);
const operatorKey3 = PrivateKey.fromString(privateKey3);

// Create names for different entities
// OEM account
const oemId = operatorId1;
const oemKey = operatorKey1;

// Manufacturer account
const manufacturerId = operatorId2;
const manufacturerKey = operatorKey2;

// Device account
const deviceId = operatorId3;
const deviceKey = operatorKey3;

// Create client for each account
const OEM = Client.forTestnet().setOperator(oemId, oemKey);
const MANUFACTURER = Client.forTestnet().setOperator(
  manufacturerId,
  manufacturerKey
);
const DEVICE = Client.forTestnet().setOperator(deviceId, deviceKey);

async function main() {
  // Import the compiled contract bytecode
  const manufacturerContractBytecode = fs.readFileSync(
    "Smart_Contract_Binary/ManufacturerContract_sol_ManufacturerContract.bin"
  );
  const oemContractBytecode = fs.readFileSync(
    "Smart_Contract_Binary/OEMContract_sol_OEMContract.bin"
  );

  // Instantiate the manufacturer smart contract
  // This contract by default instantiate the middle-man contract
  const manufacturerContractInstantiateTx = new ContractCreateFlow()
    .setBytecode(manufacturerContractBytecode)
    .setGas(1000000)
    .setConstructorParameters(new ContractFunctionParameters());
  const manufacturerContractInstantiateSubmit =
    await manufacturerContractInstantiateTx.execute(MANUFACTURER);
  const manufacturerContractInstantiateRx =
    await manufacturerContractInstantiateSubmit.getReceipt(MANUFACTURER);
  const manufacturerContractId = manufacturerContractInstantiateRx.contractId;
  console.log(
    `- The manufacturer smart contract ID is: ${manufacturerContractId} \n`
  );

  const oemContractInstantiateTx = new ContractCreateFlow()
    .setBytecode(oemContractBytecode)
    .setGas(1000000)
    .setConstructorParameters(
      new ContractFunctionParameters().addString("Makerbot")
    );
  const oemContractInstantiateSubmit = await oemContractInstantiateTx.execute(
    OEM
  );
  const oemContractInstantiateRx =
    await oemContractInstantiateSubmit.getReceipt(OEM);
  const oemContractId = oemContractInstantiateRx.contractId;
  console.log(`- The oem smart contract ID is: ${oemContractId} \n`);

  // Add OEM to the manufacturer contract
  const contractAddOEMTx = new ContractExecuteTransaction()
    .setContractId(manufacturerContractId)
    .setGas(1000000)
    .setFunction(
      "addOEM",
      new ContractFunctionParameters()
        .addAddress(publicKey1)
        .addString("Makerbot")
    );
  const contractAddOEMSubmit = await contractAddOEMTx.execute(MANUFACTURER);
  const contractAddOEMRx = await contractAddOEMSubmit.getReceipt(MANUFACTURER);
  console.log("- Added OEM to manufacturer contract \n");

  // Get the address of the middle-man contract
  const contractQueryTx1 = new ContractCallQuery()
    .setContractId(manufacturerContractId)
    .setGas(100000)
    .setFunction("getMiddleManContract", new ContractFunctionParameters());
  const contractQuerySubmit1 = await contractQueryTx1.execute(MANUFACTURER);
  const middleManAddress = contractQuerySubmit1.getAddress(0); // This address is returned in solidity format
  console.log("- Middle Man Contract Address: ", middleManAddress, "\n");

  // Add the address of the manufacturer to the OEM
  const contractAddManufacturerTx = new ContractExecuteTransaction()
    .setContractId(oemContractId)
    .setGas(1000000)
    .setFunction(
      "addManufacturer",
      new ContractFunctionParameters()
        .addAddress(middleManAddress)
        .addString("Boeing")
    );
  const contractAddManufacturerSubmit = await contractAddManufacturerTx.execute(
    OEM
  );
  const contractAddManufacturerRx =
    await contractAddManufacturerSubmit.getReceipt(OEM);
  console.log("- Adding manufacturer to OEM\n");

  // Add an update to the OEM

  // Give MAINTAINER role to OEM
  const contractGrantMaintainerTx = new ContractExecuteTransaction()
    .setContractId(oemContractId)
    .setGas(1000000)
    .setFunction(
      "grantPermission",
      new ContractFunctionParameters().addAddress(publicKey1).addUint8(0x02)
    );
  const contractGrantMaintainerSubmit = await contractGrantMaintainerTx.execute(
    OEM
  );
  const contractGrantMaintainerRx =
    await contractGrantMaintainerSubmit.getReceipt(OEM);
  console.log("- Granting maintainer permissions to OEM\n");

  // Add Update to OEM side
  const contractAddUpdate1Tx = new ContractExecuteTransaction()
    .setContractId(oemContractId)
    .setGas(1000000)
    .setFunction(
      "addUpdate",
      new ContractFunctionParameters()
        .addString("3d Printer")
        .addString("v1")
        .addUint256(0x23456789)
        .addUint256(0x34)
        .addAddress(publicKey1)
        .addAddress(publicKey2)
        .addString("https://www.google.com")
    );
  const contractAddUpdate1Submit = await contractAddUpdate1Tx.execute(OEM);
  const contractAddUpdateRx = await contractAddUpdate1Submit.getReceipt(OEM);
  console.log("- Adding update 1 to OEM\n");

  // Add Update to OEM side
  const contractAddUpdate2Tx = new ContractExecuteTransaction()
    .setContractId(oemContractId)
    .setGas(1000000)
    .setFunction(
      "addUpdate",
      new ContractFunctionParameters()
        .addString("3d Printer")
        .addString("v2")
        .addUint256(0x23456789)
        .addUint256(0x34)
        .addAddress(publicKey1)
        .addAddress(publicKey2)
        .addString("https://www.google.com")
    );
  const contractAddUpdate2Submit = await contractAddUpdate2Tx.execute(OEM);
  const contractAddUpdate2Rx = await contractAddUpdate2Submit.getReceipt(OEM);
  console.log("- Adding update 2 to OEM\n");

  // Push Update to middleman contract from OEM
  const contractPushUpdateTx = new ContractExecuteTransaction()
    .setContractId(oemContractId)
    .setGas(1000000)
    .setFunction(
      "pushUpdate",
      new ContractFunctionParameters()
        .addString("3d Printer")
        .addString("v1")
        .addString("Boeing")
    );
  const contractPushUpdateSubmit = await contractPushUpdateTx.execute(OEM);
  const contractPushUpdateRx = await contractPushUpdateSubmit.getReceipt(OEM);
  console.log("- Pushing update to middleman\n");

  // push update 2 to middleman contract from OEM
  const contractPushUpdate2Tx = new ContractExecuteTransaction()
    .setContractId(oemContractId)
    .setGas(1000000)
    .setFunction(
      "pushUpdate",
      new ContractFunctionParameters()
        .addString("3d Printer")
        .addString("v2")
        .addString("Boeing")
    );
  const contractPushUpdate2Submit = await contractPushUpdate2Tx.execute(OEM);
  const contractPushUpdate2Rx = await contractPushUpdate2Submit.getReceipt(OEM);
  console.log("- Pushing update 2 to middleman\n");

  // Call contract to add assign update permissions
  const contractGrantAssignTx = new ContractExecuteTransaction()
    .setContractId(manufacturerContractId)
    .setGas(1000000)
    .setFunction(
      "grantPermission",
      new ContractFunctionParameters().addAddress(publicKey2).addUint8(0x02)
    );
  const contractGrantAssignSubmit = await contractGrantAssignTx.execute(
    MANUFACTURER
  );
  console.log("- Granting assign permissions to manufacturer\n");

  // // Call contract to add implement update permissions
  const contractGrantImplementTx = new ContractExecuteTransaction()
    .setContractId(manufacturerContractId)
    .setGas(1000000)
    .setFunction(
      "grantPermission",
      new ContractFunctionParameters().addAddress(publicKey3).addUint8(0x01)
    );
  const contractGrantImplementSubmit = await contractGrantImplementTx.execute(
    MANUFACTURER
  );
  console.log("- Granting implement permissions to device\n");

  // Fetch Update from Manufacturer
  const contractFetchUpdateTx = new ContractExecuteTransaction()
    .setContractId(manufacturerContractId)
    .setGas(1000000)
    .setFunction(
      "assignUpdate",
      new ContractFunctionParameters()
        .addAddress(publicKey3)
        .addString("Makerbot")
        .addString("3d Printer")
        .addString("v1")
    );
  const contractFetchUpdateSubmit = await contractFetchUpdateTx.execute(
    MANUFACTURER
  );
  const contractFetchUpdateRx = await contractFetchUpdateSubmit.getReceipt(
    MANUFACTURER
  );
  console.log("- Fetching update from middleman\n");

  // Call contract to implement update
  const contractQueryTx3 = new ContractCallQuery()
    .setContractId(manufacturerContractId)
    .setGas(100000)
    .setFunction("implementUpdate", new ContractFunctionParameters());
  const contractQuerySubmit3 = await contractQueryTx3.execute(DEVICE);
  const checksum = contractQuerySubmit3.getUint256(0);
  console.log(`- The checksum is: ${checksum} \n`);
  const oem = contractQuerySubmit3.getString(1);
  console.log(`- The OEM is: ${oem} \n`);
  const device = contractQuerySubmit3.getString(2);
  console.log(`- The device is: ${device} \n`);
  const version = contractQuerySubmit3.getString(3);
  console.log(`- The version is: ${version} \n`);
  const minerId = contractQuerySubmit3.getUint256(4);
  console.log(`- The minerId is: ${minerId} \n`);
  const cid = contractQuerySubmit3.getAddress(5);
  console.log(`- The cid is: ${cid} \n`);
  const userAddress = contractQuerySubmit3.getAddress(6);
  console.log(`- The userAddress is: ${userAddress} \n`);
  const url = contractQuerySubmit3.getString(7);
  console.log(`- The url is: ${url} \n`);

  // Fetch Update 2 from Manufacturer
  const contractFetchUpdate2Tx = new ContractExecuteTransaction()
    .setContractId(manufacturerContractId)
    .setGas(1000000)
    .setFunction(
      "assignUpdate",
      new ContractFunctionParameters()
        .addAddress(publicKey3)
        .addString("Makerbot")
        .addString("3d Printer")
        .addString("v2")
    );
  const contractFetchUpdate2Submit = await contractFetchUpdate2Tx.execute(
    MANUFACTURER
  );
  const contractFetchUpdate2Rx = await contractFetchUpdate2Submit.getReceipt(
    MANUFACTURER
  );
  console.log("- Fetching update 2 from middleman\n");

  // Call contract to implement update 2
  const contractQueryTx4 = new ContractCallQuery()
    .setContractId(manufacturerContractId)
    .setGas(100000)
    .setFunction("implementUpdate", new ContractFunctionParameters());
  const contractQuerySubmit4 = await contractQueryTx4.execute(DEVICE);
  const checksum2 = contractQuerySubmit4.getUint256(0);
  console.log(`- The checksum is: ${checksum2} \n`);
  const oem2 = contractQuerySubmit4.getString(1);
  console.log(`- The OEM is: ${oem2} \n`);
  const device2 = contractQuerySubmit4.getString(2);
  console.log(`- The device is: ${device2} \n`);
  const version2 = contractQuerySubmit4.getString(3);
  console.log(`- The version is: ${version2} \n`);
  const minerId2 = contractQuerySubmit4.getUint256(4);
  console.log(`- The minerId is: ${minerId2} \n`);
  const cid2 = contractQuerySubmit4.getAddress(5);
  console.log(`- The cid is: ${cid2} \n`);
  const userAddress2 = contractQuerySubmit4.getAddress(6);
  console.log(`- The userAddress is: ${userAddress2} \n`);
  const url2 = contractQuerySubmit4.getString(7);
  console.log(`- The url is: ${url2} \n`);
}
main();
