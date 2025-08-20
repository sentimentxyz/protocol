// ABOUTME: Execute fund extraction from all Sentiment V1 contracts after upgrade
// ABOUTME: Handles LToken liquidity and account collateral extraction with batching

const { ethers } = require('ethers');

const DEPLOYED_ADDRESSES = {
  markets: {
    USDT: '0x4c8e1656E042A206EEf7e8fcff99BaC667E4623e',
    USDC: '0x0dDB1eA478F8eF0E22C7706D2903a41E94B1299B',
    FRAX: '0x2E9963ae673A885b6bfeDa2f80132CE28b784C40',
    ETH: '0xb190214D5EbAc7755899F2D96E519aa7a5776bEC',
    WBTC: '0xe520C46d5Dab5bB80aF7Dc8b821f47deB4607DB2',
    ARB: '0x21202227Bc15276E40d53889Bc83E59c3CccC121',
    OHM: '0x37E6a0EcB9e8E5D90104590049a0A197E1363b67'
  },
  core: {
    Registry: '0x17B07cfBAB33C0024040e7C299f8048F4a49679B'
  }
};

const MULTISIG = "0x000000000000000000000000000000000000dEaD"; // TODO: Update with actual multisig

async function extractFunds(privateKey) {
  const provider = new ethers.JsonRpcProvider(process.env.ARBITRUM_RPC_URL);
  const signer = new ethers.Wallet(privateKey, provider);
  
  console.log('=== Starting Fund Extraction ===');
  console.log(`Recipient: ${MULTISIG}`);
  console.log(`Signer: ${signer.address}`);
  
  // Phase 1: Extract LToken liquidity
  console.log('\n--- Extracting LToken Liquidity ---');
  
  for (const [name, address] of Object.entries(DEPLOYED_ADDRESSES.markets)) {
    try {
      const lToken = new ethers.Contract(address, [
        'function recoverFunds() external returns (uint256)'
      ], signer);
      
      const tx = await lToken.recoverFunds();
      console.log(`${name} recovery tx: ${tx.hash}`);
      await tx.wait();
    } catch (error) {
      console.error(`Failed to extract from ${name}:`, error.message);
    }
  }
  
  // Phase 2: Get all accounts with assets
  console.log('\n--- Getting Accounts with Assets ---');
  
  const registry = new ethers.Contract(
    DEPLOYED_ADDRESSES.core.Registry,
    ['function accounts(uint256) view returns (address)'],
    provider
  );
  
  // Load accounts from our scan data
  const fs = require('fs');
  const scanFiles = fs.readdirSync('./data').filter(f => f.includes('positions_final'));
  if (scanFiles.length === 0) {
    throw new Error('No position scan data found. Run smartPositionScan.js first.');
  }
  
  const latestScan = scanFiles.sort().pop();
  const scanData = JSON.parse(fs.readFileSync(`./data/${latestScan}`, 'utf8'));
  const accountsWithAssets = scanData.positions.map(p => p.account);
  
  console.log(`Found ${accountsWithAssets.length} accounts with assets`);
  
  // Phase 3: Extract from all accounts
  console.log('\n--- Extracting Account Collateral ---');
  
  const BATCH_SIZE = 50; // Process in batches to avoid gas issues
  let processed = 0;
  let extracted = 0;
  
  for (let i = 0; i < accountsWithAssets.length; i += BATCH_SIZE) {
    const batch = accountsWithAssets.slice(i, i + BATCH_SIZE);
    
    console.log(`Processing batch ${Math.floor(i/BATCH_SIZE) + 1}/${Math.ceil(accountsWithAssets.length/BATCH_SIZE)}`);
    
    const promises = batch.map(async (accountAddress) => {
      try {
        const account = new ethers.Contract(accountAddress, [
          'function recoverFunds() external'
        ], signer);
        
        const tx = await account.recoverFunds({
          gasLimit: 200000 // Set reasonable gas limit
        });
        await tx.wait();
        return { success: true, account: accountAddress, tx: tx.hash };
      } catch (error) {
        return { success: false, account: accountAddress, error: error.message };
      }
    });
    
    const results = await Promise.allSettled(promises);
    
    results.forEach((result, idx) => {
      processed++;
      if (result.status === 'fulfilled' && result.value.success) {
        extracted++;
        console.log(`✓ ${result.value.account} - ${result.value.tx}`);
      } else {
        const error = result.status === 'rejected' ? result.reason : result.value.error;
        console.log(`✗ ${batch[idx]} - ${error}`);
      }
    });
    
    console.log(`Progress: ${processed}/${accountsWithAssets.length} processed, ${extracted} extracted`);
    
    // Brief pause between batches
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
  
  console.log('\n=== Extraction Complete ===');
  console.log(`Total accounts processed: ${processed}`);
  console.log(`Successfully extracted: ${extracted}`);
  console.log(`Failed: ${processed - extracted}`);
}

// CLI execution
if (require.main === module) {
  const privateKey = process.argv[2];
  
  if (!privateKey) {
    console.log('Usage: node extractFunds.js <private_key>');
    console.log('Example: node extractFunds.js 0xabc...');
    console.log(`Funds will be sent to hardcoded multisig: ${MULTISIG}`);
    process.exit(1);
  }
  
  extractFunds(privateKey).catch(console.error);
}

module.exports = { extractFunds };