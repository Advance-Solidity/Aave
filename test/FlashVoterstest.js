const { assert } = require("chai");
const getDai = require("./getDai");

describe("Flash Vote", function () {
  let voter;
  let token;
  before(async () => {
    dai = await ethers.getContractAt(
      "IERC20",
      "0x6B175474E89094C44Da98b954EedeAC495271d0F"
    );

    const Govern = await ethers.getContractFactory("Govern");
    token = await Govern.deploy();
    await token.deployed();

    const FlashVoter = await ethers.getContractFactory("FlashVoter");
    voter = await FlashVoter.deploy(token.address, 0);
    await voter.deployed();

    await getDai(dai, [voter.address]);
  });

  describe("after flash voting", () => {
    before(async () => {
      await voter.flashVote();
    });

    it("should have recorded 100k yes votes", async () => {
      const prop = await token.proposals(0);
      assert.equal(
        prop.yesCount.toString(),
        ethers.utils.parseEther("100000").toString()
      );
    });
  });
});
