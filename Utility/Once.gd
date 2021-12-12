var did_run = false

func run_once():
	var allow = !did_run
	did_run = true
	return allow

func reset():
	did_run = false

func set_state(state):
	did_run = !!state

func get_state():
	return did_run
