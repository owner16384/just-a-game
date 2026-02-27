extends Node

enum state {
	NONE = 0,
	DRAW = 1 << 0,
	IDLE = 1 << 1,
	WALK = 1 << 2,
	RUN = 1 << 3,
	JUMP = 1 << 4
}
var currentState: int = state.NONE
