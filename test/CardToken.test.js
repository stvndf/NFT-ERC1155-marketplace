//| //TODO onlyOwner all funcs where appropriate
// TODO test uri

//TODO singleSale: the two getter functions: getCardForSingleSaleByIndex, getCardsForSingleSaleSize


//TODO consider implementing receiver

const { web3 } = require("hardhat");
const { expectRevert } = require("@openzeppelin/test-helpers");

const Contract = artifacts.require("CardToken");

contract("CardToken", (accounts) => {
  const [owner, acc1] = accounts;
  let contract;
  const uri = "www.uri.com/" //TODO do for uri test

  beforeEach(async () => {
    contract = await Contract.new("uri");
  });

  describe("Getter functions (excludes getters relating to sales)", () => {
    it("getSeasonOfTokenId function", async () => {
      await expectRevert(
        contract.getSeasonOfTokenId(0),
        "Token does not exist"
      );
      await contract.mintToken(0, 99, 1);
      assert.equal(Number(await contract.getSeasonOfTokenId(0)), 99);
    });

    it("getTokenHeldByIndex function", async () => {
      contract = await Contract.new(uri); // resetting to obtain accurate size
      await expectRevert.unspecified(contract.getTokenHeldByIndex(5)); // inexistent
      const id = 10;
      await contract.mintToken(id, 1, 1);
      const item0 = await contract.getTokenHeldByIndex(0)
      assert.equal(item0, id)
    });

    it("getTokensHeldSize and getBalanceOfTokenId functions", async () => {
      contract = await Contract.new(uri); // resetting to obtain accurate size
      assert.equal(await contract.getTokensHeldSize(), 0);
      await contract.mintToken(0, 1, 1);
      assert.equal(await contract.getTokensHeldSize(), 1);
      await contract.mintToken(0, 1, 1);
      await contract.mintToken(1, 1, 1);
      assert.equal(await contract.getTokensHeldSize(), 2);

      assert.equal(await contract.getBalanceOfTokenId(0), 2)
      assert.equal(await contract.getBalanceOfTokenId(1), 1)

    })
  });


  describe("mintToken function", () => {
    it("Does not mint season 0", async () => {
      // Enabling season 0 would cause conflict when checking existence
      await expectRevert(contract.mintToken(0, 0, 1), "Season cannot be 0");
      await contract.mintToken(0, 1, 1);
      assert.equal(Number(await contract.balanceOf(contract.address, 0)), 1);
    });

    it("Amount to mint must be at least 1", async () => {
      await expectRevert(
        contract.mintToken(1, 1, 0),
        "Must mint at least 1 of the token"
      );
      await contract.mintToken(1, 1, 1);
      assert.equal(Number(await contract.balanceOf(contract.address, 1)), 1);
    });

    it("Must not permit mismatching id-season pairs", async () => {
      await contract.mintToken(2, 1, 1);
      await contract.mintToken(2, 1, 1); // should not throw as it's the same season
      await expectRevert(
        contract.mintToken(2, 20, 1),
        "Existing id matches with a different season"
      );
    });

    it("Creates new tokenSeason mapping pair for new ids", async () => {
      await contract.mintToken(3, 2, 1);
      assert.equal(Number(await contract.getSeasonOfTokenId(3)), 2);
      await expectRevert.unspecified(contract.mintToken(3, 20, 1)); // should have no impact as it reverts
      assert.equal(Number(await contract.getSeasonOfTokenId(3)), 2);
      await contract.mintToken(4, 20, 1);
      assert.equal(Number(await contract.getSeasonOfTokenId(4)), 20);
    });

    it("Balance adds correctly", async () => {
      await contract.mintToken(5, 2, 1);
      assert.equal(Number(await contract.balanceOf(contract.address, 5)), 1);
      await contract.mintToken(5, 2, 8000);
      assert.equal(Number(await contract.balanceOf(contract.address, 5)), 8001);
    });

    it("Minting adds to _tokensHeld and tokenHeldBalances correctly", async () => {
      contract = await Contract.new(uri);
      await contract.mintToken(6, 3, 66);
      await contract.mintToken(7, 4, 7000);
      await contract.mintToken(7, 4, 10_000);

      assert.equal(Number(await contract.getTokenHeldByIndex(0)), 6)
      assert.equal(Number(await contract.getBalanceOfTokenId(6)),66)

      assert.equal(Number(await contract.getTokenHeldByIndex(1)), 7)
      assert.equal(Number(await contract.getBalanceOfTokenId(7)), 17_000)
    });
  });

  //

// SINGLE SALE:
  // setForSingleSale:
    // should remove from tokensHeld
  // buySingleToken:
    // should remove from cardsForSingleSale
    // should be xferred to person
  // removeFromSingleSale:
    // should remove from cardsForSingleSale
    // should be added back to tokensHeld
});
