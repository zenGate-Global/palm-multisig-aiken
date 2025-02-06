use aiken/list.{filter}
use aiken/transaction.{Datum, InlineDatum, Output}
use aiken/transaction/value.{AssetName, PolicyId, quantity_of}

pub fn get_inline_datum(datum: Datum) -> Data {
  when datum is {
    InlineDatum(d) -> d
    _ -> fail @"Expected inline datum"
  }
}

pub fn filter_outputs_by_token(
  outputs: List<Output>,
  policy_id: PolicyId,
  asset_name: AssetName,
) {
  outputs
    |> filter(fn(i) { quantity_of(i.value, policy_id, asset_name) > 0 })
}
