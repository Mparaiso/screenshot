start:
	@DEBUG=myapp supervisor --extensions 'js|coffee' --ignore 'node_modules' app.js &
.PHONY:start