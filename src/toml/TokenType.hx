package toml;

enum TokenType {
  TokTrue;
  TokFalse;
  TokRightBracket;
  TokLeftBracket;
  TokLeftBrace;
  TokRightBrace;
  TokEqual;
  TokDot;
  TokComma;
  TokDash;
  TokUnderline;
  TokIdentifier;
  TokNumber;
  TokString;
  TokNewline;
  TokEof;
}
