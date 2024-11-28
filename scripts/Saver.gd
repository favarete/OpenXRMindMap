extends Node

var thread := Thread.new()
var semaphore := Semaphore.new()
var mutex = Mutex.new()

var should_exit := false

func _ready() -> void:
	thread.start(_thread_function)

func _thread_function():
	while true:
		semaphore.wait()
		mutex.lock()
		
		var actual_mindmap = Globals.get_active_mindmap()
		var content = JSON.stringify(actual_mindmap)
		var file = FileAccess.open("user://new_data.json", FileAccess.WRITE)
		file.store_string(content)
		
		mutex.unlock()
		if should_exit: break

func save_current_state():
	semaphore.post()

func _exit_tree():
	should_exit = true
	
	semaphore.post()
	thread.wait_to_finish()
