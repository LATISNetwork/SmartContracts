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
  PublicKey,
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
  const contractBytecode = fs.readFileSync(
    "Smart_Contract_Binary/ManufacturerContract_sol_ManufacturerContract.bin"
  );

  // Instantiate the manufacturer smart contract
  // This contract by default instantiate the middle-man contract
  const manufacturerContractInstantiateTx = new ContractCreateFlow()
    .setBytecode(contractBytecode)
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
  console.log("Granting assign permissions to manufacturer");

  // Call contract to add implement update permissions
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
  console.log("Granting implement permissions to device");

  // Call contract to assign update
  const contractAssignUpdateTx = new ContractExecuteTransaction()
    .setContractId(manufacturerContractId)
    .setGas(1000000)
    .setFunction(
      "assignUpdate",
      new ContractFunctionParameters()
        .addAddress(publicKey3)
        .addUint256(0x34)
        .addUint256(0xff32)
        .addAddress(publicKey1)
        .addAddress(publicKey1)
    );
  const contractAssignUpdateSubmit = await contractAssignUpdateTx.execute(
    MANUFACTURER
  );
  const contractExecuteRx = await contractGrantAssignSubmit.getReceipt(
    MANUFACTURER
  );
  console.log("Assigning update to device");

  // Call contract to implement update
  const contractQueryTx3 = new ContractCallQuery()
    .setContractId(manufacturerContractId)
    .setGas(100000)
    .setFunction("implementUpdate", new ContractFunctionParameters());
  const contractQuerySubmit3 = await contractQueryTx3.execute(DEVICE);
  const checksum = contractQuerySubmit3.getUint256(0);
  console.log(`- The checksum is: ${checksum} \n`);
  const minerId = contractQuerySubmit3.getUint256(1);
  console.log(`- The miner ID is: ${minerId} \n`);
  const CID = contractQuerySubmit3.getAddress(2);
  console.log(`- The CID is: ${CID} \n`);
  const userAddress = contractQuerySubmit3.getAddress(3);
  console.log(`- The user address is: ${userAddress} \n`);

  // Get the address of the middle-man contract
  const contractQueryTx1 = new ContractCallQuery()
    .setContractId(manufacturerContractId)
    .setGas(100000)
    .setFunction("getMiddleManContract", new ContractFunctionParameters());
  const contractQuerySubmit1 = await contractQueryTx1.execute(MANUFACTURER);
  const middleManAddress = contractQuerySubmit1.getAddress(0); // This address is returned in solidity format
  console.log("Middle Man Contract Address: ", middleManAddress);

  //   const contractQueryTx2 = new ContractCallQuery()
  //     .setContractId(manufacturerContractId)
  //     .setGas(100000)
  //     .setFunction("viewUpdates", new ContractFunctionParameters());
  //   const contractQuerySubmit2 = await contractQueryTx2.execute(MANUFACTURER);
  //   const updates = contractQuerySubmit2.getString(0);
  //   console.log("Updates: ", updates);

  // Instantiate the oem smart contract
  const oemContractInstantiateTx = new ContractCreateFlow()
    .setBytecode(contractBytecode)
    .setGas(1000000)
    .setConstructorParameters(new ContractFunctionParameters());
  const oemContractInstantiateSubmit = await oemContractInstantiateTx.execute(
    OEM
  );
  const oemContractInstantiateRx =
    await oemContractInstantiateSubmit.getReceipt(OEM);
  const oemContractId = oemContractInstantiateRx.contractId;
  console.log(`- The oem smart contract ID is: ${oemContractId} \n`);

  
}
main();
