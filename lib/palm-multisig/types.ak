use sundae/multisig.{MultisigScript}

pub type Action {
  Genesis(Int, List<MultisigScript>)
  ChangeSignatures(List<MultisigScript>)
  ChangeThreshold(Int)
}

pub type MultisigDatum {
  threshold_amount: Int,
  signatures: List<MultisigScript>,
}

pub type MultisigRedeemer {
  action: Action,
}
