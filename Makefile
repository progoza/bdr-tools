install:
	mkdir -p ~/.local/bin 
	cp ./scripts/atomizeFiles.sh ~/.local/bin/bdr-atomizeFiles.sh
	cp ./scripts/split2Volumes.sh ~/.local/bin/bdr-split2Volumes.sh
	cp ./scripts/unatomizeFiles.sh ~/.local/bin/bdr-unatomizeFiles.sh

uninstall:
	rm ~/.local/bin/bdr-atomizeFiles.sh
	rm ~/.local/bin/bdr-split2Volumes.sh
	rm ~/.local/bin/bdr-unatomizeFiles.sh

