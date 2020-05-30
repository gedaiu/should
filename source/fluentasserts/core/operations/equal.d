module fluentasserts.core.operations.equal;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;

///
IResult[] equal(ref Evaluation evaluation) @safe nothrow {
  auto result = evaluation.currentValue.strValue == evaluation.expectedValue.strValue;

  if(evaluation.isNegated) {
    result = !result;
  }

  if(result) {
    return [];
  }

  IResult[] results = [];

  Lifecycle.instance.addText(" `");
  Lifecycle.instance.addValue(evaluation.currentValue.strValue);

  if(evaluation.isNegated) {
    Lifecycle.instance.addText("` is equal to `");
  } else {
    Lifecycle.instance.addText("` is not equal to `");
  }

  Lifecycle.instance.addValue(evaluation.expectedValue.strValue);
  Lifecycle.instance.addText("`.");


  try results ~= new DiffResult(evaluation.expectedValue.strValue, evaluation.currentValue.strValue); catch(Exception) {}
  try results ~= new ExpectedActualResult(evaluation.expectedValue.strValue, evaluation.currentValue.strValue); catch(Exception) {}

  return results;
}