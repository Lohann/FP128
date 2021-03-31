const { expect } = require("chai");

describe("FP128", function() {
  before(async function () {
    const FP128 = await ethers.getContractFactory("FP128Mock");
    this.fp128 = await FP128.deploy();
    await this.fp128.deployed();
  })

  it("1 + 2 = 3", async function() {
    expect(await this.fp128.add('1', '2')).to.equal('3');
  });
});
