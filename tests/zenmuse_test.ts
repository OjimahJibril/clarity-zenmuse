import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can create and modify journal entries",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const content = "Today I practiced mindful breathing";
    const timestamp = chain.blockHeight - 10;
    
    let block = chain.mineBlock([
      Tx.contractCall('zenmuse', 'create-entry', 
        [types.utf8(content), types.uint(timestamp), types.bool(false)],
        wallet1.address
      )
    ]);
    
    block.receipts[0].result.expectOk().expectUint(1);
    
    // Modify entry
    const newContent = "Updated reflection";
    block = chain.mineBlock([
      Tx.contractCall('zenmuse', 'modify-entry',
        [types.uint(1), types.utf8(newContent), types.bool(false)],
        wallet1.address
      )
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
    
    const response = chain.callReadOnlyFn(
      'zenmuse',
      'get-entry',
      [types.principal(wallet1.address), types.uint(1)],
      wallet1.address
    );
    
    response.result.expectOk();
  }
});

Clarinet.test({
  name: "Validates timestamp constraints",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const futureTimestamp = chain.blockHeight + 1000;
    
    let block = chain.mineBlock([
      Tx.contractCall('zenmuse', 'create-entry',
        [types.utf8("Future entry"), types.uint(futureTimestamp), types.bool(false)],
        wallet1.address
      )
    ]);
    
    block.receipts[0].result.expectErr(104); // err-future-timestamp
  }
});

// Additional tests remain unchanged...
