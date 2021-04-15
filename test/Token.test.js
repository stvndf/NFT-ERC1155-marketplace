const Token = artifacts.require("Token");

contract("Token", accounts => {
  it("", async () => {
    const token = await Token.new("fake uri");

    // await token.mint()


  });
});


