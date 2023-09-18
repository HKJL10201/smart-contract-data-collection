const {ethers} = require("hardhat")

module.exports = async ({deployments, getNamedAccounts}) => {
    const { deploy, log} = deployments
    const {deployer, user} = await getNamedAccounts()

    const args = [
        "100",
        "Calliope",
        "Call"
    ]

    const AuctionFactory = await deploy("SongNFT", {
    from: deployer,
    log: true,
    args: args,
    })
}