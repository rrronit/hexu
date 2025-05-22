section .data
    http_response db "HTTP/1.1 200 OK", 0x0D, 0x0A
                   db "Content-Type: text/plain", 0x0D, 0x0A
                   db "Content-Length: 18", 0x0D, 0x0A
                   db 0x0D, 0x0A
                   db "hello from server", 0x0A

    http_response_len equ $ - http_response

    socket_msg db "socket started", 0x0A
    socket_msg_len equ $ - socket_msg

    bind_msg db "bind success", 0x0A
    bind_msg_len equ $ - bind_msg

    listen_msg db "listen success", 0x0A
    listen_msg_len equ $ - listen_msg

    accept_msg db "accept success", 0x0A
    accept_msg_len equ $ - accept_msg

    reuse_val dd 1 

    sockaddr_in:
        dw 2                   ; ip version (2 = IPv4)
        dw 0x901F              ; Port 8080 
        dd 0x00000000          ; 127.0.0.1 
        dq 0                   ; zero padding

section .bss
    buffer resb 1024

section .text
    global _start
_start:
    ; socket()
    mov rax, 41              ; sys_socket
    mov rdi, 2               ; AF_INET
    mov rsi, 1               ; SOCK_STREAM
    xor rdx, rdx             ; protocol 0
    syscall
    cmp rax, 0
    jl exit_error
    mov r12, rax             ; save socket fd

    ; print "socket started"
    mov rax, 1
    mov rdi, 1
    mov rsi, socket_msg
    mov rdx, socket_msg_len
    syscall

    ; setsockopt
    mov rax, 54              ; sys_setsockopt
    mov rdi, r12             ; socket fd
    mov rsi, 1               ; SOL_SOCKET
    mov rdx, 2               ; SO_REUSEADDR
    mov r10, reuse_val       ; pointer to option value
    mov r8, 4                ; size of option
    syscall

    ; bind()
    mov rax, 49              ; sys_bind
    mov rdi, r12             ; socket fd
    mov rsi, sockaddr_in     ; sockaddr_in
    mov rdx, 16              ; sockaddr_in size
    syscall
    cmp rax, 0
    jl exit_error

    ; print "bind success"
    mov rax, 1
    mov rdi, 1
    mov rsi, bind_msg
    mov rdx, bind_msg_len
    syscall

    ; listen
    mov rax, 50
    mov rdi, r12
    mov rsi, 5
    syscall
    cmp rax, 0
    jl exit_error

    ; print "listen success"
    mov rax, 1
    mov rdi, 1
    mov rsi, listen_msg
    mov rdx, listen_msg_len
    syscall

accept_loop:
    ; accept
    mov rax, 43
    mov rdi, r12
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl exit_error
    mov r13, rax             

    ; print "accept success"
    mov rax, 1
    mov rdi, 1
    mov rsi, accept_msg
    mov rdx, accept_msg_len
    syscall

    jmp read_client

close_client:
    mov rax, 3               ; sys_close
    mov rdi, r13
    syscall
    jmp accept_loop

read_client:
    mov rax, 0               ; read
    mov rdi, r13
    mov rsi, buffer
    mov rdx, 1024
    syscall
    cmp rax, 0
    jle close_client
    mov r14, rax             ; store read length

    ; print client request to stdout
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    mov rdx, r14
    syscall

    jmp write_client

write_client:
    mov rax, 1               ; write
    mov rdi, r13
    mov rsi, http_response
    mov rdx, http_response_len
    syscall
    jmp close_client

exit_error:
    mov rax, 60
    xor rdi, rdi
    syscall
