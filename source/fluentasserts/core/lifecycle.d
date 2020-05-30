module fluentasserts.core.lifecycle;

import fluentasserts.core.evaluation;
import fluentasserts.core.operations.registry;
import fluentasserts.core.operations.equal;
import fluentasserts.core.operations.throwable;
import fluentasserts.core.results;
import fluentasserts.core.base;

import std.conv;


static this() {
  Lifecycle.instance = new Lifecycle();
  ResultGlyphs.resetDefaults;

  Registry.instance = new Registry();
  Registry.instance.register("string", "string", "equal", &equal);
  Registry.instance.register("callable", "", "throwAnyException", &throwAnyException);
  Registry.instance.register("callable", "", "throwException", &throwException);
}

/// The assert lifecycle
class Lifecycle {

  /// Global instance for the assert lifecicle
  static Lifecycle instance;

  private {
    Evaluation evaluation;

    /// The nice message printed to the user
    MessageResult message;

    /// The source code where the assert is located
    SourceResult sourceResult;

    ///
    int assertIndex;

    ///
    int totalAsserts;
  }

  void incAssertIndex() {
    assertIndex++;
  }

  /// Method called when a new value is evaluated
  Lifecycle beginEvaluation(ValueEvaluation value) @safe nothrow {
    assert(assertIndex >= 0, "assert index is `" ~ assertIndex.to!string ~ "`. It must be >= 0.");

    totalAsserts++;
    assertIndex++;

    if(assertIndex == 1) {
      evaluation.currentValue = value;
      message = new MessageResult();
    }

    return this;
  }

  /// Method called when the oracle value is known
  Lifecycle compareWith(ValueEvaluation value) @safe nothrow {
    evaluation.expectedValue = value;

    addText(" `");
    addValue(evaluation.expectedValue.strValue);
    addText("`.");

    return this;
  }

  /// Method called when the comparison operation is known
  Lifecycle usingOperation(string operationName) @safe nothrow {
    evaluation.operationName = operationName;
    addText(" ");
    addText(operationName);

    return this;
  }

  /// Method called when the operation result needs to be negated to be true
  Lifecycle usingNegation(bool value) {
    evaluation.isNegated = value;

    if(value) {
      addText(" not");
    }

    return this;
  }

  /// Method called when the assert location is known
  Lifecycle atSourceLocation(const string fileName, const size_t line) @safe nothrow {
    evaluation.fileName = fileName;
    evaluation.line = line;
    sourceResult = new SourceResult(fileName, line);

    try addText(sourceResult.getValue); catch(Exception) {}
    addText(" should");

    return this;
  }

  ///
  Lifecycle addText(string text) @safe nothrow {
    if(text == "throwAnyException") {
      text = "throw any exception";
    }

    message.addText(text);
    return this;
  }

  ///
  Lifecycle addValue(string value) @safe nothrow {
    message.addValue(value);
    return this;
  }

  ///
  EvaluationResult endEvaluation() @trusted nothrow {
    assertIndex--;
    assert(assertIndex >= 0, "assert index is `" ~ assertIndex.to!string ~ "`. It must be >= 0.");

    if(assertIndex > 0) return EvaluationResult();
    auto assertResults = Registry.instance.handle(evaluation);

    if(evaluation.currentValue.typeName != "callable" && evaluation.currentValue.throwable !is null) {
      string m;

      try m = evaluation.currentValue.throwable.message.to!string; catch(Exception) {}

      auto message = new MessageResult(m);
      auto fileName = evaluation.currentValue.throwable.file;
      auto line = evaluation.currentValue.throwable.line;

      return EvaluationResult([message], fileName, line);
    }

    if(assertResults.length == 0) {
      return EvaluationResult([], "", 0);
    }

    IResult[] results = [ message ];
    results ~= assertResults;

    return EvaluationResult(results, evaluation.fileName, evaluation.line);
  }
}

///
struct EvaluationResult {
  IResult[] results;
  string fileName;
  size_t line;

  auto because(string reason) {
    return this;
  }

  void perform() @safe {
    if(results.length == 0) {
      return;
    }

    throw new TestException(results, fileName, line);
  }

  ~this() @safe {
    this.perform;
  }
}