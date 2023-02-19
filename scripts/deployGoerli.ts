import { ethers, run } from "hardhat";
async function main() {
    const originDomain = "9991";
    const _source = "<Deployed mumbai contract address>";
    const _connext = "0xFCa08024A6D4bCc87275b1E4A1E22B71fAD7f649";
    const _cdma = "0x7Bfe603647d5380ED3909F6f87580D0Af1B228B4"
    const Parichay = await ethers.getContractFactory("parichaySBTx");
    const parichaySC = await Parichay.deploy(originDomain, _source, _connext, _cdma);
    const WAIT_BLOCK_CONFIRMATIONS = 6;

    await parichaySC.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);

    console.log("SC address:", parichaySC.address);
    await run(`verify:verify`, {
        address: parichaySC.address,
        constructorArguments: [originDomain, _source, _connext, _cdma],
      });
}
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
