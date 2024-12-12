extends Node

var thread: Thread = Thread.new()
var semaphore: Semaphore = Semaphore.new()
var mutex: Mutex = Mutex.new()

var should_exit: bool = false

func _ready() -> void:
	var saving_thread: int = thread.start(_thread_function)
	if saving_thread != OK:
		printerr("Error in saving thread!")

func _thread_function() -> void:
	while true:
		semaphore.wait()
		mutex.lock()
		
		var actual_mindmap: Dictionary = Globals.get_active_mindmap()
		var content: String = JSON.stringify(actual_mindmap)
		var file: FileAccess = FileAccess.open(Globals.SAVE_FILE, FileAccess.WRITE)
		file.store_string(content)
		
		mutex.unlock()
		if should_exit: break

func save_current_state() -> void:
	semaphore.post()

func _exit_tree() -> void:
	should_exit = true
	
	semaphore.post()
	thread.wait_to_finish()
