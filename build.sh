PROGRAM_NAME="tic-tac-toe"
LIB_DIR="lib"
BIN_DIR="bin"

if [ ! -d $LIB_DIR ]; then
  mkdir $LIB_DIR
fi
nasm -g -f elf64 -o $LIB_DIR/$PROGRAM_NAME.o $PROGRAM_NAME.asm

if [ ! -d $BIN_DIR ]; then
  mkdir $BIN_DIR
fi
ld -g -o $BIN_DIR/$PROGRAM_NAME $LIB_DIR/$PROGRAM_NAME.o