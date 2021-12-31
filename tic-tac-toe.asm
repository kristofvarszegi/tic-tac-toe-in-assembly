INPUT_SIZE          equ 3       ; 2 coordinates + enter
BOARD_HEADER_SIZE   equ 1
ROW_PRINT_LEN       equ 5
FIRST_CELL_INDEX    equ ROW_PRINT_LEN + BOARD_HEADER_SIZE
BOARD_SIZE          equ 3
PLAYER_1_SYMBOL     equ "O"
PLAYER_2_SYMBOL     equ "X"
EMPTY_CELL_SYMBOL   equ "_"

%macro retry_input_if_index_invalid 1
    cmp %1, 0
    jl invalid_input
    cmp %1, 2
    jg invalid_input
%endmacro

%macro print 2 
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, %1         ; Message
    mov rdx, %2         ; Message length
    syscall
%endmacro

section	.text
    global _start

_start:
    xor r8, r8
    print board, board_len
set_player_symbol:
    cmp r8, PLAYER_1_SYMBOL
    je set_player_2_symbol
    mov r8, PLAYER_1_SYMBOL
    jmp first_input
set_player_2_symbol:
    mov r8, PLAYER_2_SYMBOL
    jmp first_input

first_input:
    print turn_msg_beg, turn_msg_beg_len
    mov [buf], r8b
    print buf, 1
    print turn_msg_end, turn_msg_end_len
    jmp read_and_place

invalid_input:
    print invalid_input_msg, invalid_input_msg_len
    jmp read_and_place

cell_occupied:
    print cell_occupied_msg, cell_occupied_msg_len

read_and_place:
    xor rax, rax                    ; sys_read
    xor rdi, rdi                    ; stdin
    mov rsi, buf                    ; Input buffer
    mov rdx, INPUT_SIZE             ; Input buffer size
    syscall
    ; TODO empty input buffer after INPUT_SIZE chars

    xor rax, rax
    mov al, [buf]
    sub al, 0x61                    ; Row index
    retry_input_if_index_invalid al
    ; TODO accept capital letters

    xor rbx, rbx
    mov bl, [buf + 1]
    sub bl, "1"                     ; Column index
    retry_input_if_index_invalid bl

    inc al                          ; First row is the column headers
    mov dl, ROW_PRINT_LEN
    mul dl
    inc bl                          ; First column is the row headers
    add al, bl

    mov r9b, [board + rax]
    cmp r9b, EMPTY_CELL_SYMBOL
    jne cell_occupied

    mov [board + rax], r8b
    print board, board_len

; TODO optimize: if finds empty cell then rule out those win states which assume a symbol in that cell
horizontal_win_check_init:
    xor rcx, rcx
    mov cl, (BOARD_SIZE + 1)
horizontal_win_check_loop:          ; Loop through rows
    dec cl
    jz vertical_win_check_init
    xor rax, rax
    mov al, cl
    dec al
    mov dl, ROW_PRINT_LEN
    mul dl
    mov bl, EMPTY_CELL_SYMBOL
    cmp bl, [board + FIRST_CELL_INDEX + rax]
    je horizontal_win_check_loop    ; If 1st cell in row is empty, skip the rest of the check

    mov bl, [board + FIRST_CELL_INDEX + rax]
    cmp bl, [board + FIRST_CELL_INDEX + rax + 1]   ; Unrolled loop for maximum performance
    jne horizontal_win_check_loop
    cmp bl, [board + FIRST_CELL_INDEX + rax + 2]
    jne horizontal_win_check_loop
    print h_streak_msg, h_streak_msg_len
    jmp won

vertical_win_check_init:
    xor rcx, rcx
    mov cl, (BOARD_SIZE + 1)
vertical_win_check_loop:            ; Loop through columns
    dec cl
    jz principal_diagonal_win_check
    xor rax, rax
    mov al, cl
    dec al
    mov bl, EMPTY_CELL_SYMBOL
    cmp bl, [board + FIRST_CELL_INDEX + rax]
    je vertical_win_check_loop      ; If 1st cell in col is empty, skip the rest of the check

    mov bl, [board + FIRST_CELL_INDEX + rax]
    cmp bl, [board + FIRST_CELL_INDEX + ROW_PRINT_LEN + rax]   ; Unrolled loop for maximum performance
    jne vertical_win_check_loop
    cmp bl, [board + FIRST_CELL_INDEX + 2 * ROW_PRINT_LEN + rax]
    jne vertical_win_check_loop
    print v_streak_msg, v_streak_msg_len
    jmp won

principal_diagonal_win_check:
    mov bl, EMPTY_CELL_SYMBOL
    cmp bl, [board + FIRST_CELL_INDEX]
    je counter_diagonal_win_check           ; If empty cell, skip the rest of the check
    mov bl, [board + FIRST_CELL_INDEX]
    cmp bl, [board + FIRST_CELL_INDEX + (ROW_PRINT_LEN + 1)]   ; Unrolled loop for maximum performance
    jne counter_diagonal_win_check
    cmp bl, [board + FIRST_CELL_INDEX + 2 * (ROW_PRINT_LEN + 1)]
    jne counter_diagonal_win_check
    print pd_streak_msg, pd_streak_msg_len
    jmp won

counter_diagonal_win_check:
    mov bl, EMPTY_CELL_SYMBOL
    cmp bl, [board + FIRST_CELL_INDEX + (BOARD_SIZE - 1)]
    je check_if_board_is_full                                   ; If empty cell, skip the rest of the check
    mov bl, [board + FIRST_CELL_INDEX + (BOARD_SIZE - 1)]
    cmp bl, [board + FIRST_CELL_INDEX + (BOARD_SIZE - 1) + (ROW_PRINT_LEN - 1)]    ; Unrolled loop for maximum performance
    jne check_if_board_is_full
    cmp bl, [board + FIRST_CELL_INDEX + (BOARD_SIZE - 1) + 2 * (ROW_PRINT_LEN - 1)]
    jne check_if_board_is_full
    print cd_streak_msg, cd_streak_msg_len
    jmp won

check_if_board_is_full:
    xor rax, rax
    mov al, EMPTY_CELL_SYMBOL
    cmp al, [board + FIRST_CELL_INDEX + 0]     ; Unrolled loop for maximum performance
    je board_not_full
    cmp al, [board + FIRST_CELL_INDEX + 1]
    je board_not_full
    cmp al, [board + FIRST_CELL_INDEX + 2]
    je board_not_full
    cmp al, [board + FIRST_CELL_INDEX + ROW_PRINT_LEN + 0]
    je board_not_full
    cmp al, [board + FIRST_CELL_INDEX + ROW_PRINT_LEN + 1]
    je board_not_full
    cmp al, [board + FIRST_CELL_INDEX + ROW_PRINT_LEN + 2]
    je board_not_full
    cmp al, [board + FIRST_CELL_INDEX + 2 * ROW_PRINT_LEN + 0]
    je board_not_full
    cmp al, [board + FIRST_CELL_INDEX + 2 * ROW_PRINT_LEN + 1]
    je board_not_full
    cmp al, [board + FIRST_CELL_INDEX + 2 * ROW_PRINT_LEN + 2]
    je board_not_full
    jmp board_full

board_not_full:
    jmp set_player_symbol

won:
    mov [buf], r8b
    print buf, 1
    print winner_msg, winner_msg_len
    print goodbye_msg, goodbye_msg_len
    jmp _exit

board_full:
    print board_full_msg, board_full_msg_len
    print goodbye_msg, goodbye_msg_len

_exit:
    xor rdi, rdi
    mov rax, 60
    syscall

section	.data
board:      db " 123", 10, "a___", 10, "b___", 10, "c___", 10
;board:      db " 123", 10, "a_XO", 10, "bXOX", 10, "cXOX", 10 ; Test for board full w/o winner
;board:      db " 123", 10, "a___", 10, "bOO_", 10, "c___", 10 ; Test for horizontal streak
;board:      db " 123", 10, "a___", 10, "b_X_", 10, "c_X_", 10 ; Test for vertical streak
;board:      db " 123", 10, "a___", 10, "b_O_", 10, "c__O", 10 ; Test for principal diagonal streak
;board:      db " 123", 10, "a___", 10, "b_X_", 10, "cX__", 10 ; Test for counter diagonal streak
board_len:  equ $ - board
buf:        times INPUT_SIZE db 0

section .rodata
turn_msg_beg:           db "Player "
turn_msg_beg_len:       equ $ - turn_msg_beg
turn_msg_end:           db "'s turn (e.g. 'b2'): "
turn_msg_end_len:       equ $ - turn_msg_end
invalid_input_msg:      db "Invalid input. Try again: "
invalid_input_msg_len:  equ $ - invalid_input_msg
cell_occupied_msg:      db "Cell occupied. Try another: "
cell_occupied_msg_len:  equ $ - cell_occupied_msg
board_full_msg:         db "Board full w/o winner."
board_full_msg_len:     equ $ - board_full_msg
h_streak_msg:           db "Horizontal streak. "
h_streak_msg_len:       equ $ - h_streak_msg
v_streak_msg:           db "Vertical streak. "
v_streak_msg_len:       equ $ - v_streak_msg
pd_streak_msg:          db "Principal diagonal streak. "
pd_streak_msg_len:      equ $ - pd_streak_msg
cd_streak_msg:          db "Counter diagonal streak. "
cd_streak_msg_len:      equ $ - cd_streak_msg
winner_msg:             db " won!"
winner_msg_len:         equ $ - winner_msg
goodbye_msg:            db " Goodbye!", 10
goodbye_msg_len:        equ $ - goodbye_msg
