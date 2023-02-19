import { ethers} from "hardhat";

async function main() {

    const Parichay = await ethers.getContractFactory("parichaySBTy");
    const parichaySC = await Parichay.deploy();

    await parichaySC.deployed();
    console.log("SC address:", parichaySC.address);
}
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
