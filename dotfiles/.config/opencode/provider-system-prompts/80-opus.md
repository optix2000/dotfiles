---
modelRegex: "^.+/claude-opus.*$"
---

{{opencode:provider}}

Do NOT delegate to the Task tool any trivial tasks, like reading files verbatim, or exploring very small repos. If it's something you can do yourself in <10 tool calls, just do it yourself.

# On Coding

NEVER give explicit code instructions when delegating coding. DO provide context that will help better understand the problem and the scope.

## BAD

### Example 1

- Declare `let mut etl_insert_elapsed_total = Duration::ZERO;` near line 452-453 (next to the other elapsed trackers)
- Wrap the `header_number_collector.insert(...)` call (lines 466-468) with timing, adding elapsed to the cumulative total
- After the producer loop, print it with eprintln: `eprintln!("[headers] ETL insert: {etl_insert_elapsed_total:.1?}");`

### Example 2

The new code should look like this (replacing lines 599-634):
```rust
                crate::reth_db::db::write_block_body_indices(
                    &tx,
                    block_number,
                    StoredBlockBodyIndices {
                        first_tx_num,
                        tx_count,
                    },
                )?;
                if !ommers.is_empty() {
                    crate::reth_db::db::write_block_ommers(
                        &tx,
                        block_number,
                        StoredBlockOmmers { ommers },
                    )?;
                }
                if let Some(withdrawals) = withdrawals {
                    crate::reth_db::db::write_block_withdrawals(&tx, block_number, withdrawals)?;
                }
                let encode_started_at = Instant::now();
                let (tx_types, encoded_txs): (Vec<_>, Vec<Vec<u8>>) = if transactions.len() > 4 {
                    transactions
                        .into_par_iter()
                        .map(|tx| {
                            let ty = tx.tx_type();
                            let mut buf = Vec::with_capacity(256);
                            tx.to_compact(&mut buf);
                            (ty, buf)
                        })
                        .unzip()
                } else {
                    transactions
                        .into_iter()
                        .map(|tx| {
                            let ty = tx.tx_type();
                            let mut buf = Vec::with_capacity(256);
                            tx.to_compact(&mut buf);
                            (ty, buf)
                        })
                        .unzip()
                };
                encode_elapsed_total += encode_started_at.elapsed();
```

## GOOD:

### Example 1

Change 1: Eliminate freezer hashes reads in `src/convert/headers.rs`
In `read_header()`, for frozen blocks (the `if block_num >= first_frozen && block_num < last_frozen_exclusive` branch), the code currently reads the block hash from the freezer `hashes` table (lines 62-72). This is wasteful because the block hash is simply `keccak256(rlp_bytes)` of the header, and we already have those RLP bytes in `header_rlp` (fetched at lines 52-56).
