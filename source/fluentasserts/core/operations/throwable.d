module fluentasserts.core.operations.throwable;

public import fluentasserts.core.base;
import fluentasserts.core.results;
import fluentasserts.core.lifecycle;
import fluentasserts.core.expect;
import fluentasserts.core.serializers;

import std.string;
import std.conv;
import std.algorithm;
import std.array;

version(unittest) {
  class CustomException : Exception {
    this(string msg, string fileName = "", size_t line = 0, Throwable next = null) {
      super(msg, fileName, line, next);
    }
  }
}

///
IResult[] throwAnyException(ref Evaluation evaluation) @trusted nothrow {
  IResult[] results;

  evaluation.message.addText(". ");
  auto thrown = evaluation.currentValue.throwable;

  if(evaluation.currentValue.throwable && evaluation.isNegated) {
    string message;
    try message = thrown.message.to!string; catch(Exception) {}

    evaluation.message.addText("`");
    evaluation.message.addValue(thrown.classinfo.name);
    evaluation.message.addText("` saying `");
    evaluation.message.addValue(message);
    evaluation.message.addText("` was thrown.");

    try results ~= new ExpectedActualResult("No exception to be thrown", "`" ~ thrown.classinfo.name ~ "` saying `" ~ message ~ "`"); catch(Exception) {}
  }

  if(!thrown && !evaluation.isNegated) {
    evaluation.message.addText("No exception was thrown.");

    try results ~= new ExpectedActualResult("Any exception to be thrown", "Nothing was thrown"); catch(Exception) {}
  }

  if(thrown && !evaluation.isNegated && "Throwable" in evaluation.currentValue.meta) {
    string message;
    try message = thrown.message.to!string; catch(Exception) {}

    evaluation.message.addText("A `Throwable` saying `" ~ message ~ "` was thrown.");

    try results ~= new ExpectedActualResult("Any exception to be thrown", "A `Throwable` with message `" ~ message ~ "` was thrown"); catch(Exception) {}
  }

  evaluation.currentValue.throwable = null;

  return results;
}

/// It should be successfull when the function does not throw
unittest {
  void test() {}
  expect({ test(); }).to.not.throwAnyException();
}

/// It should fail when an exception is thrown and none is expected
unittest {
  void test() { throw new Exception("Test exception"); }

  bool thrown;

  try {
    expect({ test(); }).to.not.throwAnyException();
  } catch(TestException e) {
    thrown = true;

    assert(e.message.indexOf("should not throw any exception. `object.Exception` saying `Test exception` was thrown.") != -1);
    assert(e.message.indexOf("\n Expected:No exception to be thrown\n") != -1);
    assert(e.message.indexOf("\n   Actual:`object.Exception` saying `Test exception`\n") != -1);
  }

  assert(thrown, "The exception was not thrown");
}

/// It should be successfull when the function throws an expected exception
unittest {
  void test() { throw new Exception("test"); }
  expect({ test(); }).to.throwAnyException;
}

/// It should not be successfull when the function throws a throwable and an exception is expected
unittest {
  void test() { assert(false); }

  bool thrown;

  try {
    expect({ test(); }).to.throwAnyException;
  } catch(TestException e) {
    thrown = true;

    assert(e.message.indexOf("should throw any exception. A `Throwable` saying `Assertion failure` was thrown.") != -1);
    assert(e.message.indexOf("\n Expected:Any exception to be thrown\n") != -1);
    assert(e.message.indexOf("\n   Actual:A `Throwable` with message `Assertion failure` was thrown\n") != -1);
    assert(e.file == "source/fluentasserts/core/operations/throwable.d");
  }

  assert(thrown, "The exception was not thrown");
}

/// It should be successfull when the function throws an expected exception
unittest {
  void test() { throw new Exception("test"); }
  expect({ test(); }).to.throwAnyException;
}

IResult[] throwAnyExceptionWithMessage(ref Evaluation evaluation) @trusted nothrow {
  IResult[] results;

  auto thrown = evaluation.currentValue.throwable;

  if(evaluation.currentValue.throwable && evaluation.isNegated) {
    string message;
    try message = thrown.message.to!string; catch(Exception) {}

    evaluation.message.addText("`");
    evaluation.message.addValue(thrown.classinfo.name);
    evaluation.message.addText("` saying `");
    evaluation.message.addValue(message);
    evaluation.message.addText("` was thrown.");

    try results ~= new ExpectedActualResult("No exception to be thrown", "`" ~ thrown.classinfo.name ~ "` saying `" ~ message ~ "`"); catch(Exception) {}
  }

  if(!thrown && !evaluation.isNegated) {
    evaluation.message.addText("Nothing was thrown.");

    try results ~= new ExpectedActualResult("Any exception to be thrown", "Nothing was thrown"); catch(Exception) {}
  }

  if(thrown && !evaluation.isNegated && "Throwable" in evaluation.currentValue.meta) {
    string message;
    try message = thrown.message.to!string; catch(Exception) {}

    evaluation.message.addText("A `Throwable` saying `" ~ message ~ "` was thrown.");

    try results ~= new ExpectedActualResult("Any exception to be thrown", "A `Throwable` with message `" ~ message ~ "` was thrown"); catch(Exception) {}
  }

  evaluation.currentValue.throwable = null;

  return results;
}

///
IResult[] throwException(ref Evaluation evaluation) @trusted nothrow {
  evaluation.message.addText(".");

  string exceptionType = evaluation.expectedValue.strValue.cleanString;

  IResult[] results;
  auto thrown = evaluation.currentValue.throwable;

  if(thrown && evaluation.isNegated && thrown.classinfo.name == exceptionType) {
    string message;
    try message = thrown.message.to!string; catch(Exception) {}

    evaluation.message.addText("`");
    evaluation.message.addValue(thrown.classinfo.name);
    evaluation.message.addText("` saying `");
    evaluation.message.addValue(message);
    evaluation.message.addText("` was thrown.");

    try results ~= new ExpectedActualResult("no `" ~ exceptionType ~ "` to be thrown", "`" ~ thrown.classinfo.name ~ "` saying `" ~ message ~ "`"); catch(Exception) {}
  }

  if(thrown && !evaluation.isNegated && thrown.classinfo.name != exceptionType) {
    string message;
    try message = thrown.message.to!string; catch(Exception) {}

    evaluation.message.addText("`");
    evaluation.message.addValue(thrown.classinfo.name);
    evaluation.message.addText("` saying `");
    evaluation.message.addValue(message);
    evaluation.message.addText("` was thrown.");

    try results ~= new ExpectedActualResult(exceptionType, "`" ~ thrown.classinfo.name ~ "` saying `" ~ message ~ "`"); catch(Exception) {}
  }

  evaluation.currentValue.throwable = null;

  return results;
}

/// Should be able to catch a certain exception type
unittest {
  expect({
    throw new CustomException("test");
  }).to.throwException!CustomException;
}

/// It should fail when an unexpected exception is thrown
unittest {
  bool thrown;

  try {
    expect({
      throw new Exception("test");
    }).to.throwException!CustomException;
  } catch(TestException e) {
    thrown = true;

    assert(e.message.indexOf("should throwException \"fluentasserts.core.operations.throwable.CustomException\".`object.Exception` saying `test` was thrown.") != -1);
    assert(e.message.indexOf("\n Expected:fluentasserts.core.operations.throwable.CustomException\n") != -1);
    assert(e.message.indexOf("\n   Actual:`object.Exception` saying `test`\n") != -1);
    assert(e.file == "source/fluentasserts/core/operations/throwable.d");
  }

  assert(thrown, "The exception was not thrown");
}

/// It should not fail when an exception is thrown and it is not expected
unittest {
  expect({
    throw new Exception("test");
  }).to.not.throwException!CustomException;
}

/// It should fail when an different exception than the one checked is thrown
unittest {
  bool thrown;

  try {
    expect({
      throw new CustomException("test");
    }).to.not.throwException!CustomException;
  } catch(TestException e) {
    thrown = true;

    assert(e.message.indexOf("should not throwException \"fluentasserts.core.operations.throwable.CustomException\".`fluentasserts.core.operations.throwable.CustomException` saying `test` was thrown.") != -1);
    assert(e.message.indexOf("\n Expected:no `fluentasserts.core.operations.throwable.CustomException` to be thrown\n") != -1);
    assert(e.message.indexOf("\n   Actual:`fluentasserts.core.operations.throwable.CustomException` saying `test`\n") != -1);
    assert(e.file == "source/fluentasserts/core/operations/throwable.d");
  }

  assert(thrown, "The exception was not thrown");
}