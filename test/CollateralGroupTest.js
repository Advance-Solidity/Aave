const { assert } = require("chai");
const getDai = require("./getDai");
const poolABI = require("./abi.json");

describe('CollateralGroup', function () {
    const daiAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
    const poolAddress = "0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9";
    const depositAmount = ethers.utils.parseEther("10000");
    let contract;
    let members;
    before(async () => {
        dai = await ethers.getContractAt("IERC20", daiAddress);
        pool = await ethers.getContractAt(poolABI, poolAddress);

        const accounts = await ethers.provider.listAccounts();
        const deployer = accounts[0];
        members = accounts.slice(1, 4);
        await getDai(dai, members);

        const groupAddress = ethers.utils.getContractAddress({
            from: deployer,
            nonce: (await ethers.provider.getTransactionCount(deployer))
        });
        for (let i = 0; i < members.length; i++) {
            const signer = await ethers.provider.getSigner(members[i]);
            await dai.connect(signer).approve(groupAddress, depositAmount);
        }

        const CollateralGroup = await ethers.getContractFactory("CollateralGroup");
        contract = await CollateralGroup.deploy(members);
        await contract.deployed();
    });

    describe("when borrowing as a non-member", () => {
        it('should revert', async () => {
            const borrower = await ethers.provider.getSigner(5);
            const borrowAmount = ethers.utils.parseEther("500");
            let ex;
            try {
                await contract.connect(borrower).borrow(daiAddress, borrowAmount);
            }
            catch (_ex) {
                ex = _ex;
            }
            assert(ex);
        });
    });

    describe("when withdrawing as a non-member", () => {
        it('should revert', async () => {
            const signer = await ethers.provider.getSigner(5);
            let ex;
            try {
                await contract.connect(signer).withdraw();
            }
            catch (_ex) {
                ex = _ex;
            }
            assert(ex);
        });
    });

    describe("after borrowing dai", () => {
        let borrower;
        let borrowAmount = ethers.utils.parseEther("1000");
        before(async () => {
            borrower = await ethers.provider.getSigner(members[0]);
            await contract.connect(borrower).borrow(daiAddress, borrowAmount);
        });

        it('should have added the dai to the borrowers account', async () => {
            const balance = await dai.balanceOf(await borrower.getAddress());
            assert(balance.eq(borrowAmount));
        });

        it('should have an owed balance on the contract', async () => {
            const data = await pool.getUserAccountData(contract.address);
            assert(data.totalDebtETH.gt(ethers.utils.parseEther("1")));
        });

        describe("after repaying collateral + fees", () => {
            before(async () => {
                const debt = await pool.getReserveNormalizedVariableDebt(daiAddress);
                const factor = (new ethers.BigNumber.from("10")).pow("9");
                const debtInDai = debt.div(factor);
                await getDai(dai, [await borrower.getAddress()], debtInDai);

                const totalOwed = borrowAmount.add(debtInDai);
                await dai.connect(borrower).approve(contract.address, totalOwed);
                await contract.connect(borrower).repay(daiAddress, totalOwed);
            });

            it('should no longer have the dai in the borrowers account', async () => {
                const balance = await dai.balanceOf(await borrower.getAddress());
                assert(balance.eq("0"));
            });

            it('should have no owed balance on the contract', async () => {
                const data = await pool.getUserAccountData(contract.address);
                assert(data.totalDebtETH.eq("0"));
            });
        });
    });
});
