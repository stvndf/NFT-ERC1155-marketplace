// //| //TODO onlyOwner all funcs where appropriate

// //TODO consider receiver

// const { web3 } = require("hardhat");
// const { expectRevert } = require("@openzeppelin/test-helpers");

// const Contract = artifacts.require("CardToken");

// contract("CardToken", (accounts) => {
//   const [owner, acc1] = accounts;
//   let contract;
//   const uri = "https://token-cdn-domain/{id}.json";

//   beforeEach(async () => {
//     contract = await Contract.new(uri);
//   });

//   // it("Withdraw function", async () => {

//   //   it("onlyOwner", async () => {
//   //     await contract.setSale({ from: owner });
//   //     await contract.mintCyclopes(1, { value: tier1Price });
//   //     await expectRevert(
//   //       contract.withdraw({ from: acc1 }),
//   //       "Ownable: caller is not the owner"
//   //     );
//   //     await contract.withdraw({ from: owner }); // expect success
//   //   });
//   //   it("Requires a positive balance", async () => {
//   //     await expectRevert(
//   //       contract.withdraw({ from: owner }),
//   //       "Balance must be positive"
//   //     );
//   //     await contract.setSale({ from: owner });
//   //     await contract.mintCyclopes(1, { value: tier1Price });
//   //     contract.withdraw({ from: owner }); // expect success
//   //   });
//   // })

//   describe("Getter functions (excludes getters relating to sales)", () => {
//     it("getSeasonOfTokenId function", async () => {
//       await expectRevert(
//         contract.getSeasonOfTokenId(0),
//         "Token does not exist"
//       );
//       await contract.mintToken(0, 99, 1);
//       assert.equal(Number(await contract.getSeasonOfTokenId(0)), 99);
//     });

//     it("getTokenHeldByIndex function", async () => {
//       contract = await Contract.new(uri); // resetting to obtain accurate size
//       await expectRevert.unspecified(contract.getTokenHeldByIndex(5)); // inexistent
//       const id = 10;
//       await contract.mintToken(id, 1, 1);
//       const item0 = await contract.getTokenHeldByIndex(0);
//       assert.equal(item0, id);
//     });

//     it("getTokensHeldSize and getHeldBalanceOfTokenId functions", async () => {
//       contract = await Contract.new(uri); // resetting to obtain accurate size
//       assert.equal(await contract.getTokensHeldSize(), 0);
//       await contract.mintToken(0, 1, 1);
//       assert.equal(await contract.getTokensHeldSize(), 1);
//       await contract.mintToken(0, 1, 1);
//       await contract.mintToken(1, 1, 1);
//       assert.equal(await contract.getTokensHeldSize(), 2);

//       assert.equal(await contract.getHeldBalanceOfTokenId(0), 2);
//       assert.equal(await contract.getHeldBalanceOfTokenId(1), 1);
//     });
//   });

//   // describe("mintToken function", () => {
//   //   it("Does not mint season 0", async () => {
//   //     // Enabling season 0 would cause conflict when checking existence
//   //     await expectRevert(contract.mintToken(0, 0, 1), "Season cannot be 0");
//   //     await contract.mintToken(0, 1, 1);
//   //     assert.equal(Number(await contract.balanceOf(contract.address, 0)), 1);
//   //   });

//   //   it("Amount to mint must be at least 1", async () => {
//   //     await expectRevert(
//   //       contract.mintToken(1, 1, 0),
//   //       "Must mint at least 1 of the token"
//   //     );
//   //     await contract.mintToken(1, 1, 1);
//   //     assert.equal(Number(await contract.balanceOf(contract.address, 1)), 1);
//   //   });

//   //   it("Must not permit mismatching id-season pairs", async () => {
//   //     await contract.mintToken(2, 1, 1);
//   //     await contract.mintToken(2, 1, 1); // should not throw as it's the same season
//   //     await expectRevert(
//   //       contract.mintToken(2, 20, 1),
//   //       "Existing id matches with a different season"
//   //     );
//   //   });

//   //   it("Creates new tokenSeason mapping pair for new ids", async () => {
//   //     await contract.mintToken(3, 2, 1);
//   //     assert.equal(Number(await contract.getSeasonOfTokenId(3)), 2);
//   //     await expectRevert.unspecified(contract.mintToken(3, 20, 1)); // should have no impact as it reverts
//   //     assert.equal(Number(await contract.getSeasonOfTokenId(3)), 2);
//   //     await contract.mintToken(4, 20, 1);
//   //     assert.equal(Number(await contract.getSeasonOfTokenId(4)), 20);
//   //   });

//   //   it("Balance adds correctly", async () => {
//   //     await contract.mintToken(5, 2, 1);
//   //     assert.equal(Number(await contract.balanceOf(contract.address, 5)), 1);
//   //     await contract.mintToken(5, 2, 8000);
//   //     assert.equal(Number(await contract.balanceOf(contract.address, 5)), 8001);
//   //   });

//   //   it("Minting adds to _tokensHeld and tokenHeldBalances correctly", async () => {
//   //     contract = await Contract.new(uri);
//   //     await contract.mintToken(6, 3, 66);
//   //     await contract.mintToken(7, 4, 7000);
//   //     await contract.mintToken(7, 4, 10_000);

//   //     assert.equal(Number(await contract.getTokenHeldByIndex(0)), 6);
//   //     assert.equal(Number(await contract.getHeldBalanceOfTokenId(6)), 66);

//   //     assert.equal(Number(await contract.getTokenHeldByIndex(1)), 7);
//   //     assert.equal(Number(await contract.getHeldBalanceOfTokenId(7)), 17_000);
//   //   });
//   // });

//   // describe("mintTokenBatch function", () => {
//   //   it("Does not mint season 0", async () => {
//   //     // Enabling season 0 would cause conflict when checking existence
//   //     await expectRevert(
//   //       contract.mintTokenBatch([0, 100], 0, [0, 10]),
//   //       "Season cannot be 0"
//   //     );
//   //     await contract.mintTokenBatch([0, 100], 1, [1, 10]);
//   //     assert.equal(Number(await contract.balanceOf(contract.address, 0)), 1);
//   //     assert.equal(Number(await contract.balanceOf(contract.address, 100)), 10);
//   //   });

//   //   it("Amount to mint must be at least 1", async () => {
//   //     await expectRevert(
//   //       contract.mintTokenBatch([1, 101], 1, [0, 2]),
//   //       "Must mint at least 1 of the token"
//   //     );
//   //     await contract.mintTokenBatch([1, 101], 1, [1, 11]);
//   //     assert.equal(Number(await contract.balanceOf(contract.address, 1)), 1);
//   //     assert.equal(Number(await contract.balanceOf(contract.address, 101)), 11);
//   //   });

//   //   it("Must not permit mismatching id-season pairs", async () => {
//   //     await contract.mintTokenBatch([2, 102], 1, [1, 1]);
//   //     await contract.mintTokenBatch([2, 102], 1, [1, 1]); // should not throw as it's the same season
//   //     await expectRevert(
//   //       contract.mintTokenBatch([99, 2], 20, [1, 1]),
//   //       "Existing id matches with a different season"
//   //     );
//   //   });

//   //   it("Creates new tokenSeason mapping pair for new ids", async () => {
//   //     await contract.mintTokenBatch([3, 103], 2, [1, 1]);
//   //     assert.equal(Number(await contract.getSeasonOfTokenId(3)), 2);
//   //     assert.equal(Number(await contract.getSeasonOfTokenId(103)), 2);
//   //     await expectRevert.unspecified(contract.mintTokenBatch([3, 103], 20, [1, 1])); // should have no impact as it reverts
//   //     assert.equal(Number(await contract.getSeasonOfTokenId(3)), 2);
//   //     assert.equal(Number(await contract.getSeasonOfTokenId(103)), 2);
//   //     await contract.mintTokenBatch([4, 104], 20, [1, 1]);
//   //     assert.equal(Number(await contract.getSeasonOfTokenId(4)), 20);
//   //     assert.equal(Number(await contract.getSeasonOfTokenId(104)), 20);
//   //   });

//   //   it("Balance adds correctly", async () => {
//   //     await contract.mintTokenBatch([5, 105], 2, [1, 10]);
//   //     assert.equal(Number(await contract.balanceOf(contract.address, 5)), 1);
//   //     assert.equal(Number(await contract.balanceOf(contract.address, 105)), 10);
//   //     await contract.mintTokenBatch([5, 105], 2, [8000, 8000]);
//   //     assert.equal(Number(await contract.balanceOf(contract.address, 5)), 8001);
//   //     assert.equal(Number(await contract.balanceOf(contract.address, 105)), 8010);
//   //   });

//   //   it("Minting adds to _tokensHeld and tokenHeldBalances correctly", async () => {
//   //     contract = await Contract.new(uri);
//   //     await contract.mintTokenBatch([6, 106], 3, [66, 166]);
//   //     await contract.mintTokenBatch([7, 107], 4, [7_000, 17_000]);
//   //     await contract.mintTokenBatch([999, 7], 4, [1, 13_000]);

//   //     assert.equal(Number(await contract.getTokenHeldByIndex(0)), 6);
//   //     assert.equal(Number(await contract.getHeldBalanceOfTokenId(6)), 66)
//   //     assert.equal(Number(await contract.getTokenHeldByIndex(1)), 106);
//   //     assert.equal(Number(await contract.getHeldBalanceOfTokenId(106)), 166);;

//   //     assert.equal(Number(await contract.getTokenHeldByIndex(2)), 7);
//   //     assert.equal(Number(await contract.getHeldBalanceOfTokenId(7)), 20_000);
//   //   });

    
//   //   it("Minting the same token works", async () => {
//   //     contract = await Contract.new(uri);

//   //     await contract.mintTokenBatch([0, 0], 1, [10, 15]);
//   //     assert.equal(Number(await contract.balanceOf(contract.address, 0)), 25)
//   //   });
//   // });

//   describe("Single token marketplace", () => {
//     it("setSeasonPrice function", async () => {
//       await expectRevert(
//         contract.setSeasonPrice(0, web3.utils.toWei("1")),
//         "Cannot set price for season 0"
//       );
//       await contract.setSeasonPrice(1, web3.utils.toWei("1"));
//       assert.equal(
//         Number(await contract.defaultSeasonPrices(1)),
//         web3.utils.toWei("1")
//       );
//       await contract.setSeasonPrice(2, web3.utils.toWei("2"));
//       await contract.setSeasonPrice(2, web3.utils.toWei("20"));
//       assert.equal(
//         Number(await contract.defaultSeasonPrices(2)),
//         web3.utils.toWei("20")
//       );
//     });

//     it("setTokenPrice function", async () => {
//       await contract.setTokenPrice(3, web3.utils.toWei("1"));
//       assert.equal(
//         Number(await contract.tokensForSingleSalePrices(3)),
//         web3.utils.toWei("1")
//       );

//       await contract.setTokenPrice(4, web3.utils.toWei("4"));
//       await contract.setTokenPrice(4, web3.utils.toWei("40"));
//       assert.equal(
//         Number(await contract.tokensForSingleSalePrices(4)),
//         web3.utils.toWei("40")
//       );
//     });

//     context("setForSingleSale function", async () => {
//       it("Reverts as expected, getters", async () => {
//         await expectRevert(
//           contract.setForSingleSale(5, 0),
//           "Must specify an amount of at least 1"
//         );
//         await expectRevert(
//           contract.setForSingleSale(5, 1),
//           "Token does not exist"
//         );
//         await contract.mintToken(5, 1, 1);
//         await expectRevert(
//           contract.setForSingleSale(5, 1),
//           "Card or card's season must have a price set"
//         );
//         await contract.setTokenPrice(5, web3.utils.toWei("5"));
//         await expectRevert(
//           contract.setForSingleSale(5, 2),
//           "Specified amount exceeds held amount available"
//         );

//         await contract.setForSingleSale(5, 1); // should succeed

//         const tokenForSale = Number(
//           await contract.getTokenForSingleSaleByIndex(0)
//         );
//         assert.equal(tokenForSale, 5);
//         const tokensForSaleSize = Number(
//           await contract.getTokensForSingleSaleSize()
//         );
//         assert.equal(tokensForSaleSize, 1);
//       });

//       it("Removed from (_tokensHeld & _tokensHeldBalances) and added to (_tokensForSingleSale & tokensForSingleSaleBalances) appropriately", async () => {
//         contract = await Contract.new(uri);

//         await contract.mintToken(0, 1, 1);
//         await contract.mintToken(1, 1, 10);

//         assert.equal(Number(await contract.getTokensHeldSize()), 2);
//         assert.equal(Number(await contract.getHeldBalanceOfTokenId(0)), 1);
//         assert.equal(Number(await contract.getHeldBalanceOfTokenId(1)), 10);

//         await contract.setSeasonPrice(1, web3.utils.toWei("1"));
//         await contract.setForSingleSale(0, 1);
//         await contract.setForSingleSale(1, 8);

//         assert.equal(Number(await contract.getTokensHeldSize()), 1); // 1 has been removed
//         assert.equal(Number(await contract.getHeldBalanceOfTokenId(0)), 0);
//         assert.equal(Number(await contract.getHeldBalanceOfTokenId(1)), 2);

//         assert.equal(Number(await contract.getTokensForSingleSaleSize()), 2);
//         assert.equal(
//           Number(
//             await contract.tokensForSingleSaleBalances(
//               Number(await contract.getTokenForSingleSaleByIndex(0))
//             )
//           ),
//           1
//         );
//         assert.equal(
//           Number(
//             await contract.tokensForSingleSaleBalances(
//               Number(await contract.getTokenForSingleSaleByIndex(1))
//             )
//           ),
//           8
//         );
//       });
//     });

//     context("buySingleToken function", async () => {
//       it("Reverts as expected", async () => {
//         contract = await Contract.new(uri);

//         // Cannot buy token that is non-existent or held/not for sale
//         await expectRevert(
//           contract.buySingleToken(0),
//           "insufficient balance for transfer"
//         ); // non-existent token
//         await contract.mintToken(0, 1, 1);
//         await expectRevert(contract.buySingleToken(0), "Token is not for sale"); // held token

//         await contract.setSeasonPrice(1, web3.utils.toWei("5"));
//         await contract.setForSingleSale(0, 1);
//         assert.equal(Number(await contract.tokensForSingleSaleBalances(0)), 1);

//         await expectRevert(
//           contract.buySingleToken(0),
//           "Ether sent does not match price"
//         );
//         await expectRevert(
//           contract.buySingleToken(0, {
//             from: acc1,
//             value: web3.utils.toWei("6"),
//           }),
//           "Ether sent does not match price"
//         );
//         await contract.buySingleToken(0, {
//           from: acc1,
//           value: web3.utils.toWei("5"),
//         });
//         assert.equal(Number(await contract.balanceOf(acc1, 0)), 1);
//       });

//       it("Cannot buy token that has already been sold or too many", async () => {
//         contract = await Contract.new(uri);
//         const ethVal = web3.utils.toWei("0.5");

//         await contract.mintToken(0, 1, 1);
//         await contract.setTokenPrice(0, ethVal);
//         await contract.setForSingleSale(0, 1);

//         await contract.buySingleToken(0, { from: acc1, value: ethVal });
//         await expectRevert(
//           contract.buySingleToken(0, { from: acc1, value: ethVal }),
//           "insufficient balance for transfer"
//         );

//         await contract.mintToken(1, 2, 1); // new token
//         await contract.setTokenPrice(1, ethVal);
//         await contract.setForSingleSale(1, 1);
//         await contract.buySingleToken(1, { from: acc1, value: ethVal });

//         await contract.mintToken(0, 1, 2); // original token
//         await contract.setForSingleSale(0, 2);
//         await contract.buySingleToken(0, { from: acc1, value: ethVal });
//         await contract.buySingleToken(0, { from: acc1, value: ethVal });
//         await expectRevert(
//           contract.buySingleToken(0, { from: acc1, value: ethVal }),
//           "insufficient balance for transfer"
//         );
//       });

//       it("Balances update correctly", async () => {
//         contract = await Contract.new(uri);
//         const ethVal = web3.utils.toWei("0.5");

//         await contract.mintToken(0, 50, 10);
//         await contract.setSeasonPrice(50, ethVal);
//         await contract.setForSingleSale(0, 6); // half of them

//         assert.equal(Number(await contract.balanceOf(contract.address, 0)), 10);
//         assert.equal(Number(await contract.getHeldBalanceOfTokenId(0)), 4);
//         assert.equal(Number(await contract.tokensForSingleSaleBalances(0)), 6);

//         await contract.buySingleToken(0, { from: acc1, value: ethVal });

//         assert.equal(Number(await contract.balanceOf(contract.address, 0)), 9);
//         assert.equal(Number(await contract.balanceOf(acc1, 0)), 1); // new owner
//         assert.equal(Number(await contract.getHeldBalanceOfTokenId(0)), 4);
//         assert.equal(Number(await contract.tokensForSingleSaleBalances(0)), 5);
//       });
//     });

//     context("removeFromSingleSale function", () => {

//       it("Reverts as expected", async () => {
//         contract = await Contract.new(uri);

//         await expectRevert(contract.removeFromSingleSale(0, 1), "Token does not exist")
//         await contract.mintToken(0, 50, 10);
//         await expectRevert(contract.removeFromSingleSale(0, 0), "Must specify an amount of at least 1")
//         await contract.setSeasonPrice(50, "1");
//         await contract.setForSingleSale(0, 1)
//         await expectRevert(contract.removeFromSingleSale(0, 2), "Amount specified exceeds token set for sale")

//         await contract.mintToken(1, 50, 1);
//         await expectRevert(contract.removeFromSingleSale(1, 1), "Token is not for sale")
//         await contract.removeFromSingleSale(0, 1);
//         assert.equal(Number(await contract.tokensForSingleSaleBalances(0)), 0);
//       })

//       it("Balances update correctly, getters", async () => {
//         contract = await Contract.new(uri);
//         const ethVal = web3.utils.toWei("0.5");

//         await contract.mintToken(0, 50, 10);
//         await contract.setSeasonPrice(50, ethVal);
//         await contract.setForSingleSale(0, 6); // half of them

//         // Adding several buy function tests to ensure certainty of what start bals are
//         await contract.buySingleToken(0, { from: acc1, value: ethVal });
//         assert.equal(Number(await contract.balanceOf(contract.address, 0)), 9);
//         assert.equal(Number(await contract.balanceOf(acc1, 0)), 1); // new owner
//         assert.equal(Number(await contract.getHeldBalanceOfTokenId(0)), 4);
//         assert.equal(Number(await contract.tokensForSingleSaleBalances(0)), 5);

//         assert.equal(Number(await contract.getTokensForSingleSaleSize()), 1)

//         await contract.removeFromSingleSale(0, 3);
//         assert.equal(Number(await contract.balanceOf(contract.address, 0)), 9);
//         assert.equal(Number(await contract.balanceOf(acc1, 0)), 1); // new owner
//         assert.equal(Number(await contract.getHeldBalanceOfTokenId(0)), 7);
//         assert.equal(Number(await contract.tokensForSingleSaleBalances(0)), 2);

//         assert.equal(Number(await contract.getTokensForSingleSaleSize()), 1)
//         await contract.removeFromSingleSale(0, 2); // removing remaining ones in balance
//         assert.equal(Number(await contract.getTokensForSingleSaleSize()), 0)
//       });
//     })

//     describe("Pack marketplace", () => {
//       it("setPackPrice function", async () => {
//         await contract.setPackPrice(web3.utils.toWei("0.1"))
//         assert.equal(
//           String(await contract.packPrice()), web3.utils.toWei("0.1")
//         )
//         await contract.setPackPrice(web3.utils.toWei("1"))
//         assert.equal(
//           String(await contract.packPrice()), web3.utils.toWei("1")
//         )
//       })

//       context("setForPackSale function", async () => {

//         it("Reverts as expected, getters", async () => {
//           await expectRevert(
//             contract.setForPackSale(5, 0),
//             "Must specify an amount of at least 1"
//           );
//           await expectRevert(
//             contract.setForPackSale(5, 1),
//             "Token does not exist"
//           );
//           await contract.mintToken(5, 1, 1);
//           await expectRevert(
//             contract.setForPackSale(5, 1),
//             "Pack price must be set"
//           );
//           await contract.setPackPrice(web3.utils.toWei("5"));
//           await expectRevert(
//             contract.setForPackSale(5, 2),
//             "Specified amount exceeds held amount available"
//           );
  
//           await contract.setForPackSale(5, 1); // should succeed
  
//           const tokenForSale = Number(
//             await contract.getTokenForPackSaleByIndex(0)
//           );
//           assert.equal(tokenForSale, 5);
//           const tokensForSaleSize = Number(
//             await contract.getTokensForPackSaleSize()
//           );
//           assert.equal(tokensForSaleSize, 1);
//         });
  
//         it("Removed from (_tokensHeld & _tokensHeldBalances) and added to (_tokensForPackSale & tokensForPackSaleBalances) appropriately", async () => {
//           contract = await Contract.new(uri);
  
//           await contract.mintToken(0, 1, 1);
//           await contract.mintToken(1, 1, 10);
  
//           assert.equal(Number(await contract.getTokensHeldSize()), 2);
//           assert.equal(Number(await contract.getHeldBalanceOfTokenId(0)), 1);
//           assert.equal(Number(await contract.getHeldBalanceOfTokenId(1)), 10);
  
//           await contract.setPackPrice(web3.utils.toWei("1"));
//           await contract.setForPackSale(0, 1);
//           await contract.setForPackSale(1, 8);
  
//           assert.equal(Number(await contract.getTokensHeldSize()), 1); // 1 has been removed
//           assert.equal(Number(await contract.getHeldBalanceOfTokenId(0)), 0);
//           assert.equal(Number(await contract.getHeldBalanceOfTokenId(1)), 2);
  
//           assert.equal(Number(await contract.getTokensForPackSaleSize()), 2);
//           assert.equal(
//             Number(
//               await contract.tokensForPackSaleBalances(
//                 Number(await contract.getTokenForPackSaleByIndex(0))
//               )
//             ),
//             1
//           );
//           assert.equal(
//             Number(
//               await contract.tokensForPackSaleBalances(
//                 Number(await contract.getTokenForPackSaleByIndex(1))
//               )
//             ),
//             8
//           );
//         });
//       });




//     })








//     it("Is enumerable", async () => {
//       await contract.mintTokenBatch([0, 1], 1, [10, 20]);
//       await contract.setSeasonPrice(1, web3.utils.toWei("1"))
//       await contract.setForSingleSale(0, 6);
//       await contract.setPackPrice(web3.utils.toWei("1"))
//       await contract.setForPackSale(1, 15)

//       const tokensHeldSize = String(await contract.getTokensHeldSize())
//       assert.equal(tokensHeldSize, "2")
//       const tokenHeldByIndex1 = String(await contract.getTokenHeldByIndex(1))
//       assert.equal(tokenHeldByIndex1, "1")
//       const heldBalanceOfToken0 = String(await contract.getHeldBalanceOfTokenId(0))
//       assert.equal(heldBalanceOfToken0, "4")
//       const heldBalanceOfToken1 = String(await contract.getHeldBalanceOfTokenId(1))
//       assert.equal(heldBalanceOfToken1, "5")

//       const tokensForSingleSaleSize = String(await contract.getTokensForSingleSaleSize())
//       assert.equal(tokensForSingleSaleSize, "1")
//       const tokenForSingleSaleByIndex0 = String(await contract.getTokenForSingleSaleByIndex(0))
//       assert.equal(tokenForSingleSaleByIndex0, "0")
//       const tokenForSingleSaleBalances0 = String(await contract.tokensForSingleSaleBalances(0))
//       assert.equal(tokenForSingleSaleBalances0, "6")

//       const tokensForPackSaleSize = String(await contract.getTokensForPackSaleSize())
//       assert.equal(tokensForPackSaleSize, "1")
//       const tokenForPackSaleByIndex0 = String(await contract.getTokenForPackSaleByIndex(0))
//       assert.equal(tokenForPackSaleByIndex0, "1")
//       const tokenForPackSaleBalances0 = String(await contract.tokensForPackSaleBalances(1))
//       assert.equal(tokenForPackSaleBalances0, "15")
//     })
//   });
// });
