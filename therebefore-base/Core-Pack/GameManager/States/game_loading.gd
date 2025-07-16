extends game_state
class_name game_loading

var signals : signal_bus

func enter_state(man : game_manager):
	signals = Game.get_global("signal_bus")
	signals.loading_finished.connect(loading_finished)
	super.enter_state(man)


func exit_state():
	super.exit_state()


func process(delta : float):
	super.process(delta)

func loading_finished():
	signals.loading_finished.disconnect(loading_finished)
	manager.next_state()
