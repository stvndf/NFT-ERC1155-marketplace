const { web3 } = require("hardhat");
const { expectRevert } = require("@openzeppelin/test-helpers");

const Contract = artifacts.require("CardToken");

contract("CardToken", (accounts) => {
  const [owner, acc1] = accounts;
  let contract;
  const uri = "https://token-cdn-domain/{id}.json";

  beforeEach(async () => {
    contract = await Contract.new(uri);
  });

  it("onlyOwner", async () => {
    await expectRevert(
      contract.mintTokens([0, 1], 1, [10, 20], { from: acc1 }),
      "Ownable: caller is not the owner"
    );
    await contract.mintTokens([0, 1], 1, [10, 20], { from: owner });

    await expectRevert(
      contract.setSeasonPrice(1, web3.utils.toWei("1"), { from: acc1 }),
      "Ownable: caller is not the owner"
    );
    await contract.setSeasonPrice(1, web3.utils.toWei("1"), { from: owner });

    await expectRevert(
      contract.setTokenPrice(0, web3.utils.toWei("2"), { from: acc1 }),
      "Ownable: caller is not the owner"
    );
    await contract.setTokenPrice(0, web3.utils.toWei("2"), { from: owner });

    await expectRevert(
      contract.setForSingleSale(0, 4, { from: acc1 }),
      "Ownable: caller is not the owner"
    );
    await contract.setForSingleSale(0, 4, { from: owner });

    await expectRevert(
      contract.setPackPrice(web3.utils.toWei("3"), { from: acc1 }),
      "Ownable: caller is not the owner"
    );
    await contract.setPackPrice(web3.utils.toWei("3"), { from: owner });

    await expectRevert(
      contract.setForPackSale(0, 6, { from: acc1 }),
      "Ownable: caller is not the owner"
    );
    await contract.setForPackSale(0, 6, { from: owner });

    await contract.buySingleToken(0, { value: web3.utils.toWei("2") });

    await expectRevert(
      contract.withdraw({ from: acc1 }),
      "Ownable: caller is not the owner"
    );
    await contract.withdraw({ from: owner });
  });

  describe("Withdraw function", () => {
    it("onlyOwner", async () => {
      await contract.mintTokens([0, 1], 1, [10, 20]);
      await contract.setSeasonPrice(1, web3.utils.toWei("1"));
      await contract.setForSingleSale(0, 6);
      await contract.buySingleToken(0, { value: web3.utils.toWei("1") });

      await expectRevert(
        contract.withdraw({ from: acc1 }),
        "Ownable: caller is not the owner"
      );
      await contract.withdraw({ from: owner }); // expect success
    });

    it("Requires a positive balance", async () => {
      await expectRevert(
        contract.withdraw({ from: owner }),
        "Balance must be positive"
      );
      await contract.mintTokens([0, 1], 1, [10, 20]);
      await contract.setPackPrice(web3.utils.toWei("1"));
      await contract.setForPackSale(0, 10);
      await contract.buyPack({ value: web3.utils.toWei("1") });

      await contract.withdraw({ from: owner }); // expect success
    });
  });

  describe("Getter functions (excludes getters relating to sales)", () => {
    it("getSeasonOfTokenId function", async () => {
      await expectRevert(contract.getSeasonOfTokenId(0), "Inexistent");
      await contract.mintTokens([0], 99, [1]);
      assert.equal(Number(await contract.getSeasonOfTokenId(0)), 99);
    });

    it("getTokenHeldByIndex function", async () => {
      contract = await Contract.new(uri); // resetting to obtain accurate size
      await expectRevert.unspecified(contract.getTokenHeldByIndex(5)); // inexistent
      const id = 10;
      await contract.mintTokens([id], 1, [1]);
      const item0 = await contract.getTokenHeldByIndex(0);
      assert.equal(item0, id);
    });

    it("getTokensHeldSize and tokensHeldBalances functions", async () => {
      contract = await Contract.new(uri); // resetting to obtain accurate size
      assert.equal(await contract.getTokensHeldSize(), 0);
      await contract.mintTokens([0], 1, [1]);
      assert.equal(await contract.getTokensHeldSize(), 1);
      await contract.mintTokens([0], 1, [1]);
      await contract.mintTokens([1], 1, [1]);
      assert.equal(await contract.getTokensHeldSize(), 2);

      assert.equal(await contract.tokensHeldBalances(0), 2);
      assert.equal(await contract.tokensHeldBalances(1), 1);
    });
  });

  describe("Single token marketplace", () => {
    it("setSeasonPrice function", async () => {
      await expectRevert(
        contract.setSeasonPrice(0, web3.utils.toWei("1")),
        "Cannot set price for season 0"
      );
      await contract.setSeasonPrice(1, web3.utils.toWei("1"));
      assert.equal(
        Number(await contract.defaultSeasonPrices(1)),
        web3.utils.toWei("1")
      );
      await contract.setSeasonPrice(2, web3.utils.toWei("2"));
      await contract.setSeasonPrice(2, web3.utils.toWei("20"));
      assert.equal(
        Number(await contract.defaultSeasonPrices(2)),
        web3.utils.toWei("20")
      );
    });

    it("setTokenPrice function", async () => {
      await contract.setTokenPrice(3, web3.utils.toWei("1"));
      assert.equal(
        Number(await contract.tokensForSingleSalePrices(3)),
        web3.utils.toWei("1")
      );

      await contract.setTokenPrice(4, web3.utils.toWei("4"));
      await contract.setTokenPrice(4, web3.utils.toWei("40"));
      assert.equal(
        Number(await contract.tokensForSingleSalePrices(4)),
        web3.utils.toWei("40")
      );
    });

    context("setForSingleSale function", () => {
      it("Reverts as expected, getters", async () => {
        await expectRevert.unspecified(contract.setForSingleSale(5, 0));
        await expectRevert(contract.setForSingleSale(5, 1), "Inexistent");
        await contract.mintTokens([5], 1, [1]);
        await expectRevert(
          contract.setForSingleSale(5, 1),
          "Card or card's season must have a price set"
        );
        await contract.setTokenPrice(5, web3.utils.toWei("5"));
        await expectRevert(
          contract.setForSingleSale(5, 2),
          "Amount exceeds held amount available"
        );

        await contract.setForSingleSale(5, 1); // should succeed

        const tokenForSale = Number(
          await contract.getTokenForSingleSaleByIndex(0)
        );
        assert.equal(tokenForSale, 5);
        const tokensForSaleSize = Number(
          await contract.getTokensForSingleSaleSize()
        );
        assert.equal(tokensForSaleSize, 1);
      });

      it("Removed from (_tokensHeld & tokensHeldBalances) and added to (_tokensForSingleSale & tokensForSingleSaleBalances) appropriately", async () => {
        contract = await Contract.new(uri);

        await contract.mintTokens([0], 1, [1]);
        await contract.mintTokens([1], 1, [10]);

        assert.equal(Number(await contract.getTokensHeldSize()), 2);
        assert.equal(Number(await contract.tokensHeldBalances(0)), 1);
        assert.equal(Number(await contract.tokensHeldBalances(1)), 10);

        await contract.setSeasonPrice(1, web3.utils.toWei("1"));
        await contract.setForSingleSale(0, 1);
        await contract.setForSingleSale(1, 8);

        assert.equal(Number(await contract.getTokensHeldSize()), 1); // 1 has been removed
        assert.equal(Number(await contract.tokensHeldBalances(0)), 0);
        assert.equal(Number(await contract.tokensHeldBalances(1)), 2);

        assert.equal(Number(await contract.getTokensForSingleSaleSize()), 2);
        assert.equal(
          Number(
            await contract.tokensForSingleSaleBalances(
              Number(await contract.getTokenForSingleSaleByIndex(0))
            )
          ),
          1
        );
        assert.equal(
          Number(
            await contract.tokensForSingleSaleBalances(
              Number(await contract.getTokenForSingleSaleByIndex(1))
            )
          ),
          8
        );
      });
    });

    context("buySingleToken function", async () => {
      it("Reverts as expected", async () => {
        contract = await Contract.new(uri);

        // Cannot buy token that is non-existent or held/not for sale
        await expectRevert(
          contract.buySingleToken(0),
          "Insufficient balance for transfer"
        ); // non-existent token
        await contract.mintTokens([0], 1, [1]);
        await expectRevert(contract.buySingleToken(0), "Not on sale"); // held token

        await contract.setSeasonPrice(1, web3.utils.toWei("5"));
        await contract.setForSingleSale(0, 1);
        assert.equal(Number(await contract.tokensForSingleSaleBalances(0)), 1);

        await expectRevert(
          contract.buySingleToken(0),
          "Ether sent does not match price"
        );
        await expectRevert(
          contract.buySingleToken(0, {
            from: acc1,
            value: web3.utils.toWei("6"),
          }),
          "Ether sent does not match price"
        );
        await contract.buySingleToken(0, {
          from: acc1,
          value: web3.utils.toWei("5"),
        });
        assert.equal(Number(await contract.balanceOf(acc1, 0)), 1);
      });

      it("Cannot buy token that has already been sold or too many", async () => {
        contract = await Contract.new(uri);
        const ethVal = web3.utils.toWei("0.5");

        await contract.mintTokens([0], 1, [1]);
        await contract.setTokenPrice(0, ethVal);
        await contract.setForSingleSale(0, 1);

        await contract.buySingleToken(0, { from: acc1, value: ethVal });
        await expectRevert(
          contract.buySingleToken(0, { from: acc1, value: ethVal }),
          "Insufficient balance for transfer"
        );

        await contract.mintTokens([1], 2, [1]); // new token
        await contract.setTokenPrice(1, ethVal);
        await contract.setForSingleSale(1, 1);
        await contract.buySingleToken(1, { from: acc1, value: ethVal });

        await contract.mintTokens([0], 1, [2]); // original token
        await contract.setForSingleSale(0, 2);
        await contract.buySingleToken(0, { from: acc1, value: ethVal });
        await contract.buySingleToken(0, { from: acc1, value: ethVal });
        await expectRevert(
          contract.buySingleToken(0, { from: acc1, value: ethVal }),
          "Insufficient balance for transfer"
        );
      });

      it("Balances update correctly", async () => {
        contract = await Contract.new(uri);
        const ethVal = web3.utils.toWei("0.5");

        await contract.mintTokens([0], 50, [10]);
        await contract.setSeasonPrice(50, ethVal);
        await contract.setForSingleSale(0, 6); // half of them

        assert.equal(Number(await contract.balanceOf(contract.address, 0)), 10);
        assert.equal(Number(await contract.tokensHeldBalances(0)), 4);
        assert.equal(Number(await contract.tokensForSingleSaleBalances(0)), 6);

        await contract.buySingleToken(0, { from: acc1, value: ethVal });

        assert.equal(Number(await contract.balanceOf(contract.address, 0)), 9);
        assert.equal(Number(await contract.balanceOf(acc1, 0)), 1); // new owner
        assert.equal(Number(await contract.tokensHeldBalances(0)), 4);
        assert.equal(Number(await contract.tokensForSingleSaleBalances(0)), 5);
      });
    });

    context("removeFromSingleSale function", () => {
      it("Reverts as expected", async () => {
        contract = await Contract.new(uri);

        await expectRevert(contract.removeFromSingleSale(0, 1), "Inexistent");
        await contract.mintTokens([0], 50, [10]);
        await expectRevert.unspecified(contract.removeFromSingleSale(0, 0));
        await contract.setSeasonPrice(50, "1");
        await contract.setForSingleSale(0, 1);
        await expectRevert(
          contract.removeFromSingleSale(0, 2),
          "Amount exceeds token set for sale"
        );

        await contract.mintTokens([1], 50, [1]);
        await expectRevert(contract.removeFromSingleSale(1, 1), "Not on sale");
        await contract.removeFromSingleSale(0, 1);
        assert.equal(Number(await contract.tokensForSingleSaleBalances(0)), 0);
      });

      it("Balances update correctly, getters", async () => {
        contract = await Contract.new(uri);
        const ethVal = web3.utils.toWei("0.5");

        await contract.mintTokens([0], 50, [10]);
        await contract.setSeasonPrice(50, ethVal);
        await contract.setForSingleSale(0, 6); // half of them

        // Adding several buy function tests to ensure certainty of what start bals are
        await contract.buySingleToken(0, { from: acc1, value: ethVal });
        assert.equal(Number(await contract.balanceOf(contract.address, 0)), 9);
        assert.equal(Number(await contract.balanceOf(acc1, 0)), 1); // new owner
        assert.equal(Number(await contract.tokensHeldBalances(0)), 4);
        assert.equal(Number(await contract.tokensForSingleSaleBalances(0)), 5);

        assert.equal(Number(await contract.getTokensForSingleSaleSize()), 1);

        await contract.removeFromSingleSale(0, 3);
        assert.equal(Number(await contract.balanceOf(contract.address, 0)), 9);
        assert.equal(Number(await contract.balanceOf(acc1, 0)), 1); // new owner
        assert.equal(Number(await contract.tokensHeldBalances(0)), 7);
        assert.equal(Number(await contract.tokensForSingleSaleBalances(0)), 2);

        assert.equal(Number(await contract.getTokensForSingleSaleSize()), 1);
        await contract.removeFromSingleSale(0, 2); // removing remaining ones in balance
        assert.equal(Number(await contract.getTokensForSingleSaleSize()), 0);
      });
    });

    describe("Pack marketplace", () => {
      it("setPackPrice function", async () => {
        await contract.setPackPrice(web3.utils.toWei("0.1"));
        assert.equal(
          String(await contract.packPrice()),
          web3.utils.toWei("0.1")
        );
        await contract.setPackPrice(web3.utils.toWei("1"));
        assert.equal(String(await contract.packPrice()), web3.utils.toWei("1"));
      });

      context("setForPackSale function", async () => {
        it("Reverts as expected, getters", async () => {
          await expectRevert.unspecified(contract.setForPackSale(5, 0));
          await expectRevert(contract.setForPackSale(5, 1), "Inexistent");
          await contract.mintTokens([5], 1, [1]);
          await expectRevert(
            contract.setForPackSale(5, 1),
            "Pack price must be set"
          );
          await contract.setPackPrice(web3.utils.toWei("5"));
          await expectRevert(
            contract.setForPackSale(5, 2),
            "Amount exceeds held amount available"
          );

          await contract.setForPackSale(5, 1); // should succeed

          const tokenForSale = Number(
            await contract.getTokenForPackSaleByIndex(0)
          );
          assert.equal(tokenForSale, 5);
          const tokensForSaleSize = Number(
            await contract.getTokensForPackSaleSize()
          );
          assert.equal(tokensForSaleSize, 1);
        });

        it("Removed from (_tokensHeld & tokensHeldBalances) and added to (_tokensForPackSale & tokensForPackSaleBalances) appropriately", async () => {
          contract = await Contract.new(uri);

          await contract.mintTokens([0], 1, [1]);
          await contract.mintTokens([1], 1, [10]);

          assert.equal(Number(await contract.getTokensHeldSize()), 2);
          assert.equal(Number(await contract.tokensHeldBalances(0)), 1);
          assert.equal(Number(await contract.tokensHeldBalances(1)), 10);

          await contract.setPackPrice(web3.utils.toWei("1"));
          await contract.setForPackSale(0, 1);
          await contract.setForPackSale(1, 8);

          assert.equal(Number(await contract.getTokensHeldSize()), 1); // 1 has been removed
          assert.equal(Number(await contract.tokensHeldBalances(0)), 0);
          assert.equal(Number(await contract.tokensHeldBalances(1)), 2);

          assert.equal(Number(await contract.getTokensForPackSaleSize()), 2);
          assert.equal(
            Number(
              await contract.tokensForPackSaleBalances(
                Number(await contract.getTokenForPackSaleByIndex(0))
              )
            ),
            1
          );
          assert.equal(
            Number(
              await contract.tokensForPackSaleBalances(
                Number(await contract.getTokenForPackSaleByIndex(1))
              )
            ),
            8
          );
        });
      });

      context("buyPack function", () => {
        it("Reverts as expected", async () => {
          await contract.mintTokens([0, 5, 10], 1, [1, 1, 2]);
          await contract.setPackPrice(web3.utils.toWei("1"));
          await contract.setForPackSale(0, 1);

          await expectRevert(
            contract.buyPack(),
            "Ether sent does not match price"
          );
          await expectRevert(
            contract.buyPack({ value: web3.utils.toWei("1") }),
            "At least 4 cards must be available"
          );
          await contract.setForPackSale(5, 1);
          await contract.setForPackSale(10, 2);
          await contract.buyPack({ from: acc1, value: web3.utils.toWei("1") }); // now has 4 cards
          assert.equal(Number(await contract.balanceOf(acc1, 5)), 1);

          await expectRevert(
            contract.buyPack({ value: web3.utils.toWei("1") }),
            "At least 4 cards must be available"
          );
        });

        it("Balances update correctly", async () => {
          contract = await Contract.new(uri);
          const ethVal = web3.utils.toWei("0.1");

          await contract.mintTokens([0], 1, [5]);
          await contract.setPackPrice(ethVal);
          await contract.setForPackSale(0, 4);

          assert.equal(
            String(await contract.balanceOf(contract.address, 0)),
            "5"
          );
          assert.equal(
            String(await contract.tokensForPackSaleBalances(0)),
            "4"
          );
          assert.equal(String(await contract.balanceOf(acc1, 0)), "0");

          await contract.buyPack({ from: acc1, value: ethVal });

          assert.equal(String(await contract.balanceOf(acc1, 0)), "4");

          await contract.mintTokens([0, 99], 1, [4, 7]);
          await contract.setForPackSale(0, 4);
          await contract.setForPackSale(99, 7);

          assert.equal(
            String(await contract.tokensForPackSaleBalances(0)),
            "4"
          );
          assert.equal(String(await contract.tokensHeldBalances(0)), "1");
          assert.equal(
            String(await contract.tokensForPackSaleBalances(99)),
            "7"
          );
          assert.equal(String(await contract.tokensHeldBalances(99)), "0");
        });
      });

      it("removeFromPackSale balances", async () => {
        contract = await Contract.new(uri);

        await contract.mintTokens([0], 1, [10]);
        await contract.setPackPrice(web3.utils.toWei("1"));
        await contract.setForPackSale(0, 6, { from: owner });

        // Adding several buy function tests to ensure certainty of what start bals are
        await contract.buyPack({ from: acc1, value: web3.utils.toWei("1") });
        assert.equal(Number(await contract.balanceOf(contract.address, 0)), 6);
        assert.equal(Number(await contract.balanceOf(acc1, 0)), 4); // new owner
        assert.equal(Number(await contract.tokensHeldBalances(0)), 4);
        assert.equal(Number(await contract.tokensForSingleSaleBalances(0)), 0);
        assert.equal(Number(await contract.tokensForPackSaleBalances(0)), 2);

        assert.equal(Number(await contract.getTokensForPackSaleSize()), 1);

        await contract.removeFromPackSale(0, 1);
        assert.equal(Number(await contract.balanceOf(contract.address, 0)), 6);
        assert.equal(Number(await contract.balanceOf(acc1, 0)), 4); // new owner
        assert.equal(Number(await contract.tokensHeldBalances(0)), 5);
        assert.equal(Number(await contract.tokensForPackSaleBalances(0)), 1);

        assert.equal(Number(await contract.getTokensForPackSaleSize()), 1);
        await contract.removeFromPackSale(0, 1); // removing remaining one in balance
        assert.equal(Number(await contract.getTokensForSingleSaleSize()), 0);
      });
    });

    it("Is enumerable", async () => {
      await contract.mintTokens([0, 1], 1, [10, 20]);
      await contract.setSeasonPrice(1, web3.utils.toWei("1"));
      await contract.setForSingleSale(0, 6);
      await contract.setPackPrice(web3.utils.toWei("1"));
      await contract.setForPackSale(1, 15);

      const tokensHeldSize = String(await contract.getTokensHeldSize());
      assert.equal(tokensHeldSize, "2");
      const tokenHeldByIndex1 = String(await contract.getTokenHeldByIndex(1));
      assert.equal(tokenHeldByIndex1, "1");
      const heldBalanceOfToken0 = String(await contract.tokensHeldBalances(0));
      assert.equal(heldBalanceOfToken0, "4");
      const heldBalanceOfToken1 = String(await contract.tokensHeldBalances(1));
      assert.equal(heldBalanceOfToken1, "5");

      const tokensForSingleSaleSize = String(
        await contract.getTokensForSingleSaleSize()
      );
      assert.equal(tokensForSingleSaleSize, "1");
      const tokenForSingleSaleByIndex0 = String(
        await contract.getTokenForSingleSaleByIndex(0)
      );
      assert.equal(tokenForSingleSaleByIndex0, "0");
      const tokenForSingleSaleBalances0 = String(
        await contract.tokensForSingleSaleBalances(0)
      );
      assert.equal(tokenForSingleSaleBalances0, "6");

      const tokensForPackSaleSize = String(
        await contract.getTokensForPackSaleSize()
      );
      assert.equal(tokensForPackSaleSize, "1");
      const tokenForPackSaleByIndex0 = String(
        await contract.getTokenForPackSaleByIndex(0)
      );
      assert.equal(tokenForPackSaleByIndex0, "1");
      const tokenForPackSaleBalances0 = String(
        await contract.tokensForPackSaleBalances(1)
      );
      assert.equal(tokenForPackSaleBalances0, "15");
    });
  });
});
