org 100h

; =====================================================
; ENTRY
; =====================================================
start:
    mov ax, cs
    mov ds, ax

    call clear_screen
    call draw_ui

main_loop:
    mov ah, 00h
    int 16h

    cmp al, 27          ; ESC
    je exit

    cmp al, 'N'
    je send_packet
    cmp al, 'n'
    je send_packet

    cmp al, 'E'
    je inject_error
    cmp al, 'e'
    je inject_error

    cmp al, 'M'
    je multi_send
    cmp al, 'm'
    je multi_send

    jmp main_loop

; =====================================================
; SEND ONE PACKET
; =====================================================
send_packet:
    call generate_packet
    call display_sender
    call receiver_validate
    jmp main_loop

; =====================================================
; MULTI SEND (01 -> 0F)
; =====================================================
multi_send:
    mov cx, 0Fh
.multi:
    call generate_packet
    call display_sender
    call receiver_validate
    call short_delay
    loop .multi
    jmp main_loop

; =====================================================
; MANUAL ERROR INJECTION
; =====================================================
inject_error:
    xor byte [packet+1], 01h   ; flip 1 bit in data
    call display_sender
    call receiver_validate
    jmp main_loop

; =====================================================
; PACKET GENERATION (SENDER)
; =====================================================
generate_packet:
    mov al, [packet_counter]
    cmp al, 0Fh
    je .no_inc
    inc byte [packet_counter]
.no_inc:

    mov al, [packet_counter]
    mov [packet], al

    ; -------- realistic changing data --------
    mov al, [packet_counter]
    rol al, 1
    xor al, 55h
    mov [packet+1], al

    mov al, [packet_counter]
    ror al, 1
    xor al, 0AAh
    mov [packet+2], al

    mov al, [packet_counter]
    add al, 3
    xor al, 0Fh
    mov [packet+3], al

    ; -------- XOR checksum --------
    mov al, [packet+1]
    xor al, [packet+2]
    xor al, [packet+3]
    mov [packet+4], al

    ; -------- even parity --------
    xor bl, bl
    mov si, packet+1
    mov cx, 3
.par_cnt:
    mov al, [si]
    mov dl, 8
.par_bit:
    shr al, 1
    jnc .skip
    inc bl
.skip:
    dec dl
    jnz .par_bit
    inc si
    loop .par_cnt
    and bl, 1
    mov [packet+5], bl
    ret

; =====================================================
; RECEIVER VALIDATION
; =====================================================
receiver_validate:
    mov byte [rx_cnt_ok], 1
    mov byte [rx_chk_ok], 1
    mov byte [rx_par_ok], 1

    ; Counter
    mov al, [packet]
    cmp al, [packet_counter]
    je .cnt_ok
    mov byte [rx_cnt_ok], 0
.cnt_ok:

    ; Checksum
    mov al, [packet+1]
    xor al, [packet+2]
    xor al, [packet+3]
    mov [rx_checksum], al
    cmp al, [packet+4]
    je .chk_ok
    mov byte [rx_chk_ok], 0
.chk_ok:

    ; Parity
    xor bl, bl
    mov si, packet+1
    mov cx, 3
.par_chk:
    mov al, [si]
    mov dl, 8
.par_bit2:
    shr al, 1
    jnc .skip2
    inc bl
.skip2:
    dec dl
    jnz .par_bit2
    inc si
    loop .par_chk
    and bl, 1
    mov [rx_parity], bl
    cmp bl, [packet+5]
    je .par_ok
    mov byte [rx_par_ok], 0
.par_ok:

    call display_receiver
    call display_status
    ret

; =====================================================
; DISPLAY SENDER
; =====================================================
display_sender:
    mov dh, 5
    mov dl, 5
    call set_cursor
    mov si, s_pkt
    call print_string
    mov al, [packet]
    call print_hex

    mov dh, 6
    call set_cursor
    mov si, s_d1
    call print_string
    mov al, [packet+1]
    call print_hex

    mov dh, 7
    call set_cursor
    mov si, s_d2
    call print_string
    mov al, [packet+2]
    call print_hex

    mov dh, 8
    call set_cursor
    mov si, s_d3
    call print_string
    mov al, [packet+3]
    call print_hex

    mov dh, 9
    call set_cursor
    mov si, s_chk
    call print_string
    mov al, [packet+4]
    call print_hex

    mov dh, 10
    call set_cursor
    mov si, s_par
    call print_string
    mov al, [packet+5]
    call print_hex
    ret

; =====================================================
; DISPLAY RECEIVER
; =====================================================
display_receiver:
    mov dh, 5
    mov dl, 45
    call set_cursor
    mov si, r_cnt
    call print_string
    call show_cnt

    mov dh, 6
    call set_cursor
    mov si, r_chk
    call print_string
    call show_chk

    mov dh, 7
    call set_cursor
    mov si, r_par
    call print_string
    call show_par

    mov dh, 9
    call set_cursor
    mov si, r_rxchk
    call print_string
    mov al, [packet+4]
    call print_hex

    mov dh, 10
    call set_cursor
    mov si, r_chkcalc
    call print_string
    mov al, [rx_checksum]
    call print_hex

    mov dh, 11
    call set_cursor
    mov si, r_rxpar
    call print_string
    mov al, [packet+5]
    call print_hex

    mov dh, 12
    call set_cursor
    mov si, r_parcalc
    call print_string
    mov al, [rx_parity]
    call print_hex
    ret

; =====================================================
; FINAL STATUS
; =====================================================
display_status:
    mov dh, 14
    mov dl, 20
    call set_cursor

    cmp byte [rx_cnt_ok], 0
    je .bad_cnt
    cmp byte [rx_chk_ok], 0
    je .bad_chk
    cmp byte [rx_par_ok], 0
    je .bad_par

    mov si, ok_msg
    call print_string
    ret
.bad_cnt:
    mov si, bad_cnt
    call print_string
    ret
.bad_chk:
    mov si, bad_chk
    call print_string
    ret
.bad_par:
    mov si, bad_par
    call print_string
    ret

; =====================================================
; PASS / FAIL HELPERS
; =====================================================
show_cnt:
    cmp byte [rx_cnt_ok], 1
    je show_pass
    jmp show_fail
show_chk:
    cmp byte [rx_chk_ok], 1
    je show_pass
    jmp show_fail
show_par:
    cmp byte [rx_par_ok], 1
    je show_pass
show_fail:
    mov si, txt_fail
    call print_string
    ret
show_pass:
    mov si, txt_pass
    call print_string
    ret

; =====================================================
; UI HELPERS
; =====================================================
clear_screen:
    mov ax, 0600h
    mov bh, 1Fh
    mov cx, 0000h
    mov dx, 184Fh
    int 10h
    ret

set_cursor:
    mov ah, 02h
    mov bh, 0
    int 10h
    ret

print_string:
.next:
    lodsb
    cmp al, 0
    je .done
    mov ah, 0Eh
    int 10h
    jmp .next
.done:
    ret

print_hex:
    push ax
    mov ah, al
    shr al, 4
    call hex_digit
    mov al, ah
    and al, 0Fh
    call hex_digit
    pop ax
    ret

hex_digit:
    add al, '0'
    cmp al, '9'
    jle .ok
    add al, 7
.ok:
    mov ah, 0Eh
    int 10h
    ret

short_delay:
    mov cx, 0FFFFh
.d:
    loop .d
    ret

; =====================================================
; STATIC UI
; =====================================================
draw_ui:
    mov dh, 1
    mov dl, 8
    call set_cursor
    mov si, title
    call print_string

    mov dh, 3
    mov dl, 5
    call set_cursor
    mov si, sender
    call print_string

    mov dh, 3
    mov dl, 45
    call set_cursor
    mov si, receiver
    call print_string

    mov dh, 18
    mov dl, 5
    call set_cursor
    mov si, help
    call print_string
    ret

; =====================================================
; EXIT
; =====================================================
exit:
    mov ah, 4Ch
    int 21h

; =====================================================
; DATA
; =====================================================
packet_counter db 00h
packet db 6 dup(0)

rx_cnt_ok db 0
rx_chk_ok db 0
rx_par_ok db 0
rx_checksum db 0
rx_parity db 0

title db "TELEMETRY SENDER - RECEIVER MONITOR",0
sender db "SENDER SIDE",0
receiver db "RECEIVER SIDE",0

s_pkt db "Packet Counter : ",0
s_d1  db "Data Byte 1    : ",0
s_d2  db "Data Byte 2    : ",0
s_d3  db "Data Byte 3    : ",0
s_chk db "Checksum (TX)  : ",0
s_par db "Parity (TX)    : ",0

r_cnt db "Counter Check  : ",0
r_chk db "Checksum Check : ",0
r_par db "Parity Check   : ",0
r_rxchk db "Checksum RX    : ",0
r_chkcalc db "Checksum CALC  : ",0
r_rxpar db "Parity RX      : ",0
r_parcalc db "Parity CALC    : ",0

ok_msg  db "FINAL STATUS : PACKET VALID           ",0
bad_cnt db "FINAL STATUS : COUNTER MISMATCH      ",0
bad_chk db "FINAL STATUS : CHECKSUM MISMATCH     ",0
bad_par db "FINAL STATUS : PARITY MISMATCH       ",0

txt_pass db "PASS",0
txt_fail db "FAIL",0

help db "[N] Send  [E] Inject Error  [M] Multi-send  [ESC] Exit",0
