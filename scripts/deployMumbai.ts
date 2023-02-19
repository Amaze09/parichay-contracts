import { ethers, run } from "hardhat";
async function main() {
  // const verifierContract = "ERC20Verifier";
  // const verifierName = "ERC20zkAirdrop";
  // const verifierSymbol = "zkERC20";
  const connextAddr = "0x2334937846Ab2A3FCE747b32587e1A1A2f6EEC5a"
  const Parichay = await ethers.getContractFactory("parichaySBT");
  const parichaySC = await Parichay.deploy(connextAddr);

  const WAIT_BLOCK_CONFIRMATIONS = 5;
  await parichaySC.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);

  console.log("SC address:", parichaySC.address);

  await run(`verify:verify`, {
    address: parichaySC.address,
    constructorArguments: [connextAddr],
  });
  
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
