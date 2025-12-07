AS := nasm #this sets the assembler command to nasm
ISO_DIR := iso #this is the directoey where where the ISO structure is stored
GRUB_DIR := $(ISO_DIR)/boot/grub #the directory for grub files inside the iso
KERNEL := $(GRUB_DIR)/kernel.bin #where the assembled kernel will be put
ISO := kernel.iso # Name of the ISO file that  is gonna be made

.PHONY: all clean install iso run # Declares phony targets

all: $(ISO)

# Build the kernel by assembling loader.asm and placing output into GRUB
$(KERNEL): loader.asm | $(GRUB_DIR)
    $(AS) -f bin loader.asm -o $@ #Assembles loader.asm into binary format

# Ensure GRUB directory exists and if it doesnt then this is the thing that makes it
$(GRUB_DIR):
    mkdir -p $@

# Create ISO. it will try to use grub-mkrescue, if it can't it should fall back to genisoimage/mkisofs.
$(ISO): $(KERNEL)
    @echo "Creating ISO: $@"
    @if command -v grub-mkrescue >/dev/null 2>&1 ; then \
        grub-mkrescue -o $@ $(ISO_DIR) 2>/dev/null || { echo "grub-mkrescue failed"; exit 1; }; \
    else \
        if command -v genisoimage >/dev/null 2>&1 ; then \
            genisoimage -R -b boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 4 -boot-info-table -o $@ $(ISO_DIR); \
        else \
            if command -v mkisofs >/dev/null 2>&1 ; then \
                mkisofs -R -b boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 4 -boot-info-table -o $@ $(ISO_DIR); \
            else \
                echo "Neither grub-mkrescue nor genisoimage/mkisofs found. Install one to build the ISO."; exit 1; \
            fi \ #if spelled backwards to end it. whoever thought of this is the only funny computer scientist
        fi \
    fi

# Convenience target: ensure kernel is copied into GRUB tree (idempotent)
install: $(KERNEL)
    @echo "Kernel is already placed in $(GRUB_DIR)"

# Run the built ISO in QEMU
run: $(ISO)
    @echo "Starting QEMU with $(ISO)"
    @if command -v qemu-system-i386 >/dev/null 2>&1 ; then \
        qemu-system-i386 -cdrom $(ISO); \
    elif command -v qemu-system-x86_64 >/dev/null 2>&1 ; then \
        qemu-system-x86_64 -cdrom $(ISO); \
    else \
        echo "QEMU not found. Install qemu-system-i386 or qemu-system-x86_64 to run the ISO."; exit 1; \
    fi

#cleans generated files and any leftover kernel binaries
clean:
    rm -f $(ISO)
    rm -f $(KERNEL)
    -find $(ISO_DIR) -type f -name 'kernel.bin' -delete || true
