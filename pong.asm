; ============================================================
; MINESWEEPER ENGINE - FASM DOS TEXT MODE
; ============================================================
; Compile with: fasm demo.asm demo.com
; Run in DOSBox or real DOS.
; ============================================================

org 100h

; ============================================================
; CONFIG
; ============================================================
SCREEN_W = 80
SCREEN_H = 25

; initial rect size (used to seed the variables)
INIT_RECT_W = 4
INIT_RECT_H = 2

; ============================================================
; CONSTANTS
; ============================================================
VIDEO_SEG = 0B800h

COLOR_BLACK = 0Fh
COLOR_RED   = 4Fh

BLANK_BLACK = COLOR_BLACK * 256 + 32   ; 0F20h
BLANK_RED   = COLOR_RED   * 256 + 32   ; 4F20h

; ============================================================
; CODE
; ============================================================
start:
    ; set video mode 3 (80x25 color text)
    mov ax, 0003h
    int 10h

    ; hide cursor
    mov ah, 01h
    mov cx, 2000h
    int 10h

    ; init game state
    mov word [rect_x], 40
    mov word [rect_y], 12
    mov word [rect_w], INIT_RECT_W
    mov word [rect_h], INIT_RECT_H
    mov byte [running], 1

; ============================================================
; MAIN LOOP
; ============================================================
game_loop:
    cmp byte [running], 0
    je  .done

    call read_keys
    call update
    call render
    call delay

    jmp game_loop

.done:
    mov ah, 01h
    mov cx, 0607h
    int 10h

    mov ax, 4C00h
    int 21h

; ============================================================
; READ KEYS - non-blocking WASD
; ============================================================
read_keys:
    mov ah, 01h
    int 16h
    jz  .none

    mov ah, 00h
    int 16h

    cmp al, 'w'
    je  .up
    cmp al, 'W'
    je  .up
    cmp al, 's'
    je  .down
    cmp al, 'S'
    je  .down
    ret

.up:
    sub word [paddle_y], 3
    ret
.down:
    add word [paddle_y], 3
    ret


.none:
    ret

; ============================================================
; UPDATE - clamp to screen using runtime rect_w / rect_h
; ============================================================
update:


.check_x:
mov ax, [ball_x]
cmp ax, 78
jge .flip_x


.check_y:
mov ax, [ball_y]
cmp ax, 23
jge .flip_y


mov ax, [ball_x]
cmp ax, 0
jl .reset_ball


.check_y2:
mov ax, [ball_y]
cmp ax, 0
jle .flip_y


;check x
mov ax, [ball_x]
mov bx, [paddle_x]
cmp ax, bx
jne .move_ball

;check y
mov ax, [ball_y]
mov bx, [paddle_y]
cmp ax, bx
jl .move_ball

;check y
mov ax, [ball_y]
mov bx, [paddle_y]
add bx, 4
cmp ax, bx
jg .move_ball


jmp .flip_x






jmp .move_ball

.reset_ball:
    mov word [ball_x], 40
    mov word [ball_y], 12
jmp .move_ball

.flip_x:
    neg [ball_vx]


    ; add position
    mov ax, [ball_x]
    mov bx, [ball_vx]
    add ax, bx
    mov [ball_x], ax

    mov ax, [ball_y]
    mov bx, [ball_vy]
    add ax, bx
    mov [ball_y], ax

    jmp .check_y

.flip_y:
    neg [ball_vy]


    ; add position
    mov ax, [ball_x]
    mov bx, [ball_vx]
    add ax, bx
    mov [ball_x], ax

    mov ax, [ball_y]
    mov bx, [ball_vy]
    add ax, bx
    mov [ball_y], ax

    jmp .check_x

.move_ball:
    mov ax, [ball_x]
    mov bx, [ball_vx]
    add ax, bx
    mov [ball_x], ax

    mov ax, [ball_y]
    mov bx, [ball_vy]
    add ax, bx
    mov [ball_y], ax

    ret

; ============================================================
; RENDER - clear + draw rect
; ============================================================
render:
    mov ax, VIDEO_SEG
    mov es, ax
    xor di, di
    mov cx, SCREEN_W * SCREEN_H
    mov ax, BLANK_BLACK
    rep stosw

;    mov ax, [rect_x]
;    mov bx, [rect_y]
;    mov cx, [rect_w]       ; <-- runtime width
;    mov dx, [rect_h]       ; <-- runtime height
;    mov si, BLANK_RED
;    call fillrect


    mov ax, [ball_x]
    mov bx, [ball_y]
    mov cx, 2       ; <-- runtime width
    mov dx, 1       ; <-- runtime height
    mov si, BLANK_RED
    call fillrect


    mov ax, [paddle_x]
    mov bx, [paddle_y]
    mov cx, 1       ; <-- runtime width
    mov dx, 4       ; <-- runtime height
    mov si, BLANK_RED
    call fillrect


    ret

; ============================================================
; FILLRECT
; in:  AX = x (col), BX = y (row)
;      CX = width,     DX = height   (runtime values)
;      SI = blank cell word (attr<<8 | char)
; ============================================================
fillrect:
    push ax
    push bx
    push cx
    push dx
    push di
    push es

    ; guard: width <= 0 -> nothing to draw
    test cx, cx
    jle .skip

    ; guard: height <= 0 -> nothing to draw
    test dx, dx
    jle .skip

    ; clamp width
    mov di, ax
    add di, cx
    cmp di, SCREEN_W
    jle .w_ok
    mov cx, SCREEN_W
    sub cx, ax
    jle .skip
.w_ok:

    ; clamp height
    mov di, bx
    add di, dx
    cmp di, SCREEN_H
    jle .h_ok
    mov dx, SCREEN_H
    sub dx, bx
    jle .skip
.h_ok:

    ; ES = video segment
    mov di, VIDEO_SEG
    mov es, di

    ; DI = (y*80 + x) * 2
    mov di, bx
    imul di, SCREEN_W
    add di, ax
    add di, di              ; *2 bytes per cell

.row_loop:
    push cx
    push di

.col_loop:
    mov word [es:di], si
    add di, 2
    loop .col_loop

    pop di
    pop cx
    add di, SCREEN_W * 2
    dec dx
    jnz .row_loop

.skip:
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ============================================================
; DELAY ~50ms via BIOS tick
; ============================================================
delay:
    push ax
    push bx
    push cx

    mov ah, 00h
    int 1Ah
    mov bx, dx

.wait:
    mov ah, 00h
    int 1Ah
    sub dx, bx
    cmp dx, 1
    jb  .wait

    pop cx
    pop bx
    pop ax
    ret

; ============================================================
; DATA
; ============================================================
rect_x  dw 0
rect_y  dw 0

rect_w  dw 0            ; width  in cells (runtime)
rect_h  dw 0            ; height in cells (runtime)

ball_x dw 40
ball_y dw 12
ball_vx dw 1
ball_vy dw 1

paddle_x dw 4
paddle_y dw 10

running db 1
