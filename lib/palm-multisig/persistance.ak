use aiken/collection/list
use cardano/transaction.{Output}
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
    ChangeSignatures -> {
      let new_signature_count = list.length(signatures)

      if new_signature_count < input_datum.threshold_amount {
        fail @"threshold must be updated to a value at least as large as the number of new signatures"
      } else {
        input_datum.threshold_amount == threshold_amount
      }
    }
    ChangeThreshold -> {
      let signature_count = list.length(signatures)

      if signature_count < threshold_amount {
        fail @"threshold must be updated to a value at most as large as the number of signatures"
      } else {
        // sigs must not change, threshold can be any amount up to the signature count
        input_datum.signatures == signatures
      }
    }
    _ -> False
  }
}
