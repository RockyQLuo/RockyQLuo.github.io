CURRENT_TIME := $(shell date "+%Y-%m-%d %H:%M:%S")
commit ?="update at $(CURRENT_TIME)"

push: 
	cp -rf /Users/qluo/gits/notebook/notebook/image /Users/qluo/gits/RockyQLuo.github.io/assets/img
	git add .
	git commit -m "$(commit)"
	git push
help:
	@echo "make commit=xxx"