import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can create and retrieve journal entries",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const content = "Today I practiced mindful breathing";
    const timestamp = 1683900000;
    
    let block = chain.mineBlock([
      Tx.contractCall('zenmuse', 'create-entry', 
        [types.utf8(content), types.uint(timestamp), types.bool(false)],
        wallet1.address
      )
    ]);
    
    block.receipts[0].result.expectOk().expectUint(1);
    
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
  name: "Can set and track mindfulness goals",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('zenmuse', 'set-goal',
        [types.utf8("Daily meditation"), types.uint(30), types.ascii("DAYS")],
        wallet1.address
      )
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
  }
});

Clarinet.test({
  name: "Can get AI prompts",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    const response = chain.callReadOnlyFn(
      'zenmuse',
      'get-prompt',
      [],
      wallet1.address
    );
    
    response.result.expectOk();
  }
});

Clarinet.test({
  name: "User stats update correctly",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    // Create multiple entries
    let block = chain.mineBlock([
      Tx.contractCall('zenmuse', 'create-entry',
        [types.utf8("Entry 1"), types.uint(1683900000), types.bool(false)],
        wallet1.address
      ),
      Tx.contractCall('zenmuse', 'create-entry', 
        [types.utf8("Entry 2"), types.uint(1683900000), types.bool(false)],
        wallet1.address
      )
    ]);
    
    const response = chain.callReadOnlyFn(
      'zenmuse',
      'get-user-stats',
      [types.principal(wallet1.address)],
      wallet1.address
    );
    
    // Verify stats updated
    const stats = response.result;
    assertEquals(stats.totalEntries, 2);
    assertEquals(stats.streak, 2);
  }
});
