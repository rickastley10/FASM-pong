org 100h

start:
    ; === Initialize Game (Set VGA Mode 13h: 320x200, 256 colors) ===
    mov ax, 0013h
    int 10h

game_loop:
    ; === Check for keyboard input ===
    

    mov ax, [ball_vx]
    add [ball_x], ax

    mov ax, [ball_vy]
    add [ball_y], ax
    jmp .checkballpos
    
    .pass:

    mov ah, 01h
    int 16h
    jz .render                  ; If no key pressed, skip to render

    ; Read the actual key
    mov ah, 00h
    int 16h
    
    cmp al, 'w'                 ; Check if lowercase 'w'
    je .handle_w
    cmp al, 'W'                 ; Check if uppercase 'W'
    je .handle_w


    cmp al, '1'
    je .speedUP
    cmp al, '2'
    je .speedDOWN


    cmp al, 's'                 ; Check if lowercase 's'
    je .handle_s
    cmp al, 'S'                 ; Check if uppercase 'S'
    je .handle_s

    cmp al, 27                  ; ESC key to quit game
    je .exit
    jmp .render

    


; =====================================

.handle_w:
    add [paddle_y], -20         ; Move up
    jmp .render                 ; Jump to render (prevent falling into handle_s)

.handle_s:
    add [paddle_y], 20          ; Move down
    jmp .render                 ; Jump to render


.speedUP:

mov [time1], 0000h;  0003h
mov [time2], 2710h;  0D40h
mov [time3], 86h  ;  86h

jmp .render

.speedDOWN:

mov [time1], 0003h;  0000h
mov [time2], 0D40h;  2710h
mov [time3], 86h  ;  86h

jmp .render

.checkballpos:
    .again:
    
    mov ax, 310
    cmp [ball_x], ax
    je .ball_vel_flip_x

    
    mov ax, 190
    cmp [ball_y], ax
    je .ball_vel_flip_y


    mov ax, 30
    cmp [ball_x], ax
    je .paddle_collision_check

    .continue_checkballpos:
    mov ax, 0
    cmp [ball_y], ax
    je .ball_vel_flip_y
    

    mov ax, 0
    cmp [ball_y], ax
    je .ball_vel_flip_y




;----

    mov ax, 320
    cmp [ball_x], ax
    ja .goto_centre

    
    mov ax, 200
    cmp [ball_y], ax
    ja .goto_centre


    mov ax, 0
    cmp [ball_y], ax
    jl .goto_centre
    

    mov ax, 0
    cmp [ball_y], ax
    jl .goto_centre



jmp .pass

.ball_vel_flip_x:

    mov ax, [ball_vx]
    neg ax
    mov [ball_vx], ax


jmp .pass


.ball_vel_flip_y:

    mov ax, [ball_vy]
    neg ax
    mov [ball_vy], ax


jmp .pass

.paddle_collision_check:
    ; === MINIMAL CHANGE 1: Calculate bottom of ball instead ===
    mov ax, [ball_y]
    add ax, 10
    cmp ax, [paddle_y] 
    jl .continue_checkballpos   ; If ball bottom is higher than paddle top, miss!
    

.paddle_collision_check2:
    ; === MINIMAL CHANGE 2: Fix logic to see if top of ball is above paddle bottom ===
    mov ax, [paddle_y]
    add ax, 40
    cmp [ball_y], ax 
    jbe .ball_vel_flip_x        ; If ball top <= paddle bottom, it's a hit! Flip speed.

jmp .continue_checkballpos

.goto_centre:
    mov ax, 200
    mov [ball_x], ax
    mov ax, 100
    mov [ball_y], ax
jmp .pass
; =====================================

.render:
    ; === Clear Screen (Render Background: Color 0 = Black) ===
    mov ax, 0a000h              ; VGA video memory segment
    mov es, ax
    xor di, di                  ; Start at pixel (0,0)
    mov cx, 320*200             ; Total pixels to clear
    xor al, al                  ; Color index 0 (Black)
    rep stosb                   ; Fill video memory

    ; === Draw Rectangle Routine ===
    mov ax, [paddle_y]          ; Starting Y coordinate
    mov bx, 320
    mul bx                      ; AX = Y * 320
    add ax, [paddle_x]          ; AX = (Y * 320) + X
    mov di, ax                  ; DI = Base memory offset for top-left corner

    mov cx, 40                  ; Height counter (40 rows high)
.draw_row:
    push cx                     ; Save row counter
    push di                     ; Save current row's starting memory position
    
    mov cx, 10                  ; Width counter (10 pixels wide)
    mov al, 15                  ; Color index 15 (Bright White)
    rep stosb                   ; Fill 10 pixels horizontally
    
    pop di                      ; Restore row starting position
    add di, 320                 ; Move DI down exactly 1 line to the next row
    pop cx                      ; Restore row counter
    loop .draw_row              ; Repeat for all 40 rows

    ; === Draw Ball Routine (10x10 Square) ===
    mov ax, [ball_y]            ; Starting Y coordinate for ball
    mov bx, 320
    mul bx                      ; AX = Y * 320
    add ax, [ball_x]            ; AX = (Y * 320) + X
    mov di, ax                  ; DI = Base memory offset for ball's top-left corner

    mov cx, 10                  ; Height counter (10 rows high)
.draw_ball_row:
    push cx                     ; Save ball row counter
    push di                     ; Save current ball row's memory offset
    
    mov cx, 10                  ; Width counter (10 pixels wide)
    mov al, 14                  ; Color index 14 (Yellow)
    rep stosb                   ; Fill 10 pixels horizontally
    
    pop di                      ; Restore ball row memory offset
    add di, 320                 ; Move down 1 line to the next row
    pop cx                      ; Restore ball row counter
    loop .draw_ball_row         ; Repeat for all 10 rows

    ; === Delay / Frame Rate Timing (CHANGED HERE: 10ms for 100 FPS) ===

    mov cx, [time1]
    mov dx, [time2]
    mov ah, [time3]
    int 15h

    ; Loop forever unless exited
    jmp game_loop

.exit:
    ; === Restore Standard Text Mode (Mode 03h) and exit ===
    mov ax, 0003h
    int 10h
    
    mov ax, 4c00h
    int 21h

; === Variables (Placed safely at the end of the file) ===
var_x dw 0                      ; Variable 'x' initialized to 0
paddle_x dw 20
paddle_y dw 100

ball_x dw 200
ball_y dw 100

ball_vx dw 5
ball_vy dw 5


time1 dw 0000h;  0003h
time2 dw 2710h;  0D40h
time3 db 86h  ;  86h
