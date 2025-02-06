use aiken/transaction.{Output}
use palm_multisig/types.{
  ChangeSignatures, ChangeThreshold, MultisigDatum, MultisigRedeemer,
}
use palm_multisig/utils.{get_inline_datum}

pub fn valid_datum_recreation(
  input_datum: MultisigDatum,
  output: Output,
  redeemer: MultisigRedeemer,
) -> Bool {
  expect MultisigDatum { threshold_amount, signatures }: MultisigDatum =
    get_inline_datum(output.datum)

  when redeemer.action is {
    ChangeSignatures(new_signatures) -> and {
        (new_signatures == signatures)?,
        (input_datum.threshold_amount == threshold_amount)?,
      }
    ChangeThreshold(new_threshold_amount) -> and {
        (input_datum.signatures == signatures)?,
        (new_threshold_amount == threshold_amount)?,
      }
    _ -> False
  }
}
