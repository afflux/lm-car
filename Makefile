SHELL = /bin/bash
LODEV = /dev/loop0
IMGFN = disk.img
CC = gcc -std=c1x -ggdb -m64 -ffreestanding -mcmodel=kernel -O0 -Wall -Wextra
LD = ld -melf_x86_64 -nostdlib -z max-page-size=0x1000
QEMU = qemu-system-x86_64
QEMUFLAGS = -hda disk.img -net none $(QEMUARGS)

all: rundbg

clean:
	rm -f .copy
	rm -f boot.o kernel64.o
	rm -f kernel

veryclean: clean
	rm -f disk.img .disk

.disk:
	dd if=/dev/zero bs=4096 count=32768 of=$(IMGFN) status=none
	/sbin/parted -s $(IMGFN) mklabel msdos >/dev/null
	/sbin/parted -s $(IMGFN) mkpart primary ext2 2048s 100% >/dev/null
	sudo losetup $(LODEV) $(IMGFN)
	sudo partprobe $(LODEV)
	sudo mke2fs -q $(LODEV)p1
	sudo mount $(LODEV)p1 /mnt
	sudo mkdir -p /mnt/grub
	echo -e '(hd0)\t$(LODEV)' | sudo tee /mnt/grub/device.map > /dev/null
	sudo grub-install --modules 'part_msdos ext2 normal' --boot-directory /mnt $(LODEV)
	sudo chgrp disk -R /mnt
	sudo chmod g+w -R /mnt
	sudo umount /mnt
	sudo losetup -d $(LODEV)
	touch $@

.copy: kernel grub.cfg .disk
	sudo losetup $(LODEV) $(IMGFN)
	sudo partprobe $(LODEV)
	sudo mount $(LODEV)p1 /mnt
	cp grub.cfg /mnt/grub/
	sed -i s/OUTPUT/$</g /mnt/grub/grub.cfg
	cp $< /mnt/
	touch $@
	sudo umount /mnt
	sudo losetup -d $(LODEV)

%.o: %.S constants.h
	$(CC) -c -o $@ $<

%.o: %.c
	$(CC) -c -o $@ $<

kernel: linker.ld boot.o kernel64.o
	$(LD) -o $@ -T $^


rundbg: .copy
	gdb-multiarch -ex 'break start64' -ex 'target remote | exec $(QEMU) $(QEMUFLAGS) -S -gdb stdio' kernel

run: .copy
	$(QEMU) $(QEMUFLAGS)

.PHONY: run rundbg clean veryclean
