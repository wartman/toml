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
  TokIdentifier;
  TokNumber;
  TokString;
  TokNewline;
  TokEof;
}
