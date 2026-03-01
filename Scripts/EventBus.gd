extends Node

enum state {
	NONE = 0,
	DRAW = 1 << 0,
	WALK = 1 << 1,
	RUN = 1 << 2,
	JUMP = 1 << 3
}
var currentState: int = state.NONE
