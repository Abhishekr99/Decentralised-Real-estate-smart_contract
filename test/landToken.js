const landToken = artifacts.require("landToken");

contract ('landToken', (accounts) => {
    it('Should properly intialize', async () => {
        const landTokenInstance = await landToken.deployed();
        
        const _name =  await landTokenInstance.name();
        const _symbol = await landTokenInstance.symbol(); 

        assert.equal(_name, 'land', "Name not intialized");
        assert.equal(_symbol, 'Land', "Symbol not intialized");
    });
    it('Should add the land correctly', async () => {
        const landTokenInstance = await landToken.deployed();
        const availableLand = (await landTokenInstance.balanceOf.call(accounts[0])).toNumber();

        await landTokenInstance.addLand('location', 1, { from: accounts[0] });

        const updatedavailableLand = (await landTokenInstance.balanceOf.call(accounts[0])).toNumber();

        assert.equal(updatedavailableLand, availableLand + 1, "Land wasn't added correctly");
    });
    it('Should buy land properly', async () => {
        const landTokenInstance = await landToken.deployed();
        
        await landTokenInstance.addLand('location', 1, { from: accounts[0] });
        const sellerAcc = (await landTokenInstance.balanceOf.call(accounts[0])).toNumber();
        const buyerAcc = (await landTokenInstance.balanceOf.call(accounts[1])).toNumber();

        await landTokenInstance.buyLand(0, { from: accounts[1] , value: 10**18});

        const sellerAccUpdate = (await landTokenInstance.balanceOf.call(accounts[0])).toNumber();
        const buyerAccUpdate = (await landTokenInstance.balanceOf.call(accounts[1])).toNumber();

        assert.equal(sellerAccUpdate, sellerAcc - 1, "Land wasn't sold correctly");
        assert.equal(buyerAccUpdate, buyerAcc + 1, "Land wasn't bought correctly");
    });
    it('Should approve land properly', async () => {
        const landTokenInstance = await landToken.deployed();
        const sellerAcc = (await landTokenInstance.balanceOf.call(accounts[0])).toNumber();
        const approverAcc = accounts[5];

        await landTokenInstance.approve(approverAcc, 0, { from: accounts[1]});

        const Acc = await landTokenInstance.getApproved(0);

        assert.equal(Acc, approverAcc, "Land not approved correctly");
    });
    it('Account address should never be zero', async () => {
        const landTokenInstance = await landToken.deployed();
        let err = null;
        try {
          await landTokenInstance.balanceOf.call(0)
        } catch (error) {
          err = error
        }
        assert.ok(err instanceof Error)
    })
    it('Buyer cannot be the owner', async () => {
        const landTokenInstance = await landToken.deployed();
        await landTokenInstance.addLand('location', 1, { from: accounts[0] });
        let err = null;
        try {
          await landTokenInstance.buyLand(0, { from: accounts[0] , value: 10**18})
        } catch (error) {
          err = error
        }
        assert.isFalse(err instanceof Error)
    })
    it('Seller does not own the token', async () => {
        const landTokenInstance = await landToken.deployed();
        await landTokenInstance.addLand('location', 1, { from: accounts[0] });
        let err = null;
        try {
          await landTokenInstance.safeTransferFrom(accounts[1],accounts[2],0)
        } catch (error) {
          err = error
        }
        assert.isTrue(err instanceof Error)
    })
    it('Amount insufficient to buy', async () => {
        const landTokenInstance = await landToken.deployed();
        await landTokenInstance.addLand('location', 2, { from: accounts[0] });
        let err = null;
        try {
          await landTokenInstance.buyLand(0, { from: accounts[0] , value: 10**18})
        } catch (error) {
          err = error
        }
        assert.isFalse(err instanceof Error)
    })
    it('Approval to current owner', async () => {
        const landTokenInstance = await landToken.deployed();
        await landTokenInstance.addLand('location', 1, { from: accounts[0] });
        let err = null;
        try {
          await landTokenInstance.approve(accounts[0], 0)
        } catch (error) {
          err = error
        }
        assert.isTrue(err instanceof Error)
    })
});