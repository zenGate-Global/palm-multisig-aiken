use aiken/collection/list.{filter}
use cardano/assets.{AssetName, PolicyId, quantity_of}
use cardano/transaction.{Datum, InlineDatum, Output}

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
