
*
*

* Structure allocated by the eval.library and only by it !!
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
MAX_OPERANDS=128
MAX_OPERATORS=128
MAX_PRIORITIES=128
MAX_TOKENS=128

	rsreset
Token			rs.b 0
tk_Stack_Operands	rs.l MAX_OPERANDS
tk_Stack_Operators	rs.l MAX_OPERATORS
tk_Stack_Priorities	rs.b MAX_PRIORITIES
tk_Stack_Tokens		rs.l MAX_TOKENS
tk_Stack_Eval		rs.l MAX_OPERANDS
tk_SIZEOF		rs.b 0
